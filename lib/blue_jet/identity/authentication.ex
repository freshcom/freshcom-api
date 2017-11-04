# defmodule BlueJet.Identity.Authentication do
#   alias BlueJet.Repo
#   alias BlueJet.Identity.User
#   alias BlueJet.Identity.Customer
#   alias BlueJet.Identity.Jwt
#   alias BlueJet.Identity.RefreshToken

#   # Get token using :username and :password
#   def get_token(%{ "grant_type" => "password", "username" => username, "password" => password, "scope" => scope }), do: get_token(%{ username: username, password: password, scope: deserialize_scope(scope) })
#   def get_token(%{ username: username, password: password, scope: "" <> _ = scope }), do: get_token(%{ username: username, password: password, scope: deserialize_scope(scope) })
#   def get_token(%{ username: nil }), do: {:error, %{ error: :invalid_request, error_description: "Email can't be blank." }}
#   def get_token(%{ password: nil }), do: {:error, %{ error: :invalid_request, error_description: "Password can't be blank." }}
#   def get_token(%{ username: username, password: password, scope: %{ "type" => "user" } = scope }) do
#     with {:ok, user} <- get_user(username),
#          {:ok, account_id} <- extract_account_id(scope, user),
#          true <- Comeonin.Bcrypt.checkpw(password, user.encrypted_password),
#          refresh_token <- Repo.get_by!(RefreshToken, user_id: user.id, account_id: account_id)
#     do
#       access_token = generate_access_token(refresh_token)
#       {:ok, %{ access_token: access_token, token_type: "bearer", expires_in: 3600, refresh_token: refresh_token.id }}
#     else
#       false -> {:error, %{ error: :invalid_grant, error_description: "Username and password does not match." }}
#       {:error, :not_found} -> {:error, %{ error: :invalid_grant, error_description: "Username and password does not match." }}
#       {:error, :invalid_access_token} -> {:error, %{ error: :invalid_request, error_description: "Access Token is invalid." }}
#     end
#   end
#   def get_token(%{ username: username, password: password, scope: %{ "type" => "customer", "account_id" => account_id } }) do
#     with {:ok, _} <- Ecto.UUID.dump(account_id),
#          {:ok, customer} <- get_customer(account_id, username),
#          true <- Comeonin.Bcrypt.checkpw(password, customer.encrypted_password),
#          refresh_token <- Repo.get_by!(RefreshToken, customer_id: customer.id, account_id: account_id)
#     do
#       access_token = generate_access_token(refresh_token)
#       {:ok, %{ access_token: access_token, token_type: "bearer", expires_in: 3600, refresh_token: refresh_token.id }}
#     else
#       :error -> {:error, %{ error: :invalid_request, error_description: "Access Token is invalid"}}
#       {:error, :not_found} -> {:error, %{ error: :invalid_grant, error_description: "Username and password does not match." }}
#       false -> {:error, %{ error: :invalid_grant, error_description: "Username and password does not match." }}
#       {:error, :invalid_access_token} -> {:error, %{ error: :invalid_request, error_description: "Access Token is invalid." }}
#     end
#   end
#   # Get token using :refresh_token
#   def get_token(%{ "grant_type" => "refresh_token", "refresh_token" => refresh_token }), do: get_token(%{ refresh_token: refresh_token })
#   def get_token(%{ refresh_token: "" }), do: {:error, %{ error: :invalid_grant, error_description: "refresh_token is invalid, expired or revoked."}}
#   def get_token(%{ refresh_token: refresh_token }) do
#     with {:ok, _} <- Ecto.UUID.dump(refresh_token),
#          {:ok, refresh_token} <- get_refresh_token(refresh_token)
#     do
#       access_token = generate_access_token(refresh_token)
#       {:ok, %{ access_token: access_token, token_type: "bearer", expires_in: 3600, refresh_token: refresh_token.id }}
#     else
#       :error -> {:error, %{ error: :invalid_grant, error_description: "refresh_token is invalid, expired or revoked."}}
#       {:error, :not_found} -> {:error, %{ error: :invalid_grant, error_description: "refresh_token is invalid, expired or revoked."}}
#     end
#   end
#   def get_token(_), do: {:error, %{ error: :invalid_request }}

#   def deserialize_scope(scope_string) do
#     scopes = String.split(scope_string, ",")
#     Enum.reduce(scopes, %{}, fn(scope, acc) ->
#       with [key, value] <- String.split(scope, ":") do
#         Map.put(acc, key, value)
#       else
#         _ -> acc
#       end
#     end)
#   end

#   defp generate_access_token(%RefreshToken{ account_id: account_id, customer_id: nil, user_id: nil }) do
#     Jwt.sign_token(%{ exp: System.system_time(:second) + 3600, prn: account_id, typ: "account" })
#   end
#   defp generate_access_token(%RefreshToken{ account_id: account_id, customer_id: nil, user_id: user_id }) do
#     Jwt.sign_token(%{ exp: System.system_time(:second) + 3600, aud: account_id, prn: user_id, typ: "user" })
#   end
#   defp generate_access_token(%RefreshToken{ account_id: account_id, customer_id: customer_id, user_id: nil }) do
#     Jwt.sign_token(%{ exp: System.system_time(:second) + 3600, aud: account_id, prn: customer_id, typ: "customer" })
#   end

#   defp extract_account_id(%{ "account_id" => account_id }, _) do
#     {:ok, account_id}
#   end
#   defp extract_account_id(_, %User{ default_account_id: account_id }) do
#     {:ok, account_id}
#   end

#   defp get_refresh_token(id) do
#     refresh_token = Repo.get(RefreshToken, id)

#     if refresh_token do
#       {:ok, refresh_token}
#     else
#       {:error, :not_found}
#     end
#   end

#   defp get_user(email) do
#     user = Repo.get_by(User, email: email)

#     if user do
#       {:ok, user}
#     else
#       {:error, :not_found}
#     end
#   end

#   defp get_customer(account_id, email) do
#     customer = Repo.get_by(Customer, account_id: account_id, email: email)

#     if customer do
#       {:ok, customer}
#     else
#       {:error, :not_found}
#     end
#   end
# end
