defmodule BlueJet.Identity.Authentication do

  @moduledoc """
  Storefront Refresh Token
  %{ user_id: nil, account_id: "test-test-test-test" }

  User Account Refresh Token
  %{ user_id: "test-test-test-test", account_id: "test-test-test-test" }

  User Global Refresh Token
  %{ user_id: "test-test-test-test", account_id: nil }


  Storefront Access Token
  %{ exp: 3600, aud: "", prn: "account_id:test-test-test-test", typ: "storefront" }

  User Account Access Token
  %{ exp: 3600, aud: "account_id:test-test-test-test", prn": "user_id:test-test-test", typ: "user" }

  User Global Access Token
  %{ exp: 3600, aud: "", prn": "user_id:test-test-test", typ: "user" }


  Request for Storefront Access Token
  %{ "grant_type" => "refresh_token", "refresh_token" => "storefront-refresh-token" }

  Request for User Account Access Token
  %{ "grant_type" => "password", "username" => "test1@example.com", "password" => "test1234", "scope" => "account_id:test-test-test-test" }
  %{ "grant_type" => "refresh_token", "refresh_token" => "user-account-refresh-token" }
  %{ "grant_type" => "refresh_token", "refresh_token" => "user-global-refresh-token", scope => "account_id:test-test-test-test" }

  Request for User Global Account Access Token
  %{ "grant_type" => "password", "username" => "test1@example.com", "password" => "test1234" }
  %{ "grant_type" => "refresh_token", "refresh_token" => "user-global-access-token" }
  """

  alias BlueJet.Repo
  alias BlueJet.Identity.User
  alias BlueJet.Identity.Jwt
  alias BlueJet.Identity.RefreshToken

  def create_token(request = %{ "grant_type" => "password", "username" => username, "password" => password, "scope" => scope }) do
    create_token(%{
      grant_type: "password",
      username: username,
      password: password,
      scope: deserialize_scope(scope)
    })
  end
  def create_token(request = %{ "grant_type" => "refresh_token", "refresh_token" => refresh_token, "scope" => scope }) do
    create_token(%{
      grant_type: "password",
      refresh_token: refresh_token,
      scope: deserialize_scope(scope)
    })
  end

  def create_token(%{ grant_type: "refresh_token", refresh_token: refresh_token_id }) do
    create_storefront_token(refresh_token_id)
  end
  def create_token(%{ grant_type: "password", username: username, password: password, scope: %{ account_id: account_id } }) do
    create_user_account_token(username, password, account_id)
  end

  def create_storefront_token(refresh_token_id) do
    refresh_token = Repo.get(RefreshToken, refresh_token_id)

    if refresh_token do
      token = Jwt.sign_token(%{ exp: System.system_time(:second) + 3600, prn: "account_id:#{refresh_token.account_id}", typ: "storefront" })
      {:ok, %{ access_token: token, token_type: "bearer", expires_in: 3600, refresh_token: refresh_token.id }}
    else
      {:error, %{ error: :invalid_grant, error_description: "Refresh Token is invalid." }}
    end
  end

  def create_user_account_token(username, password, account_id) do
    user =
      User
      |> User.Query.member_of_account(account_id)
      |> Repo.get_by(email: username)

    if user && Comeonin.Bcrypt.checkpw(password, user.encrypted_password) do
      with refresh_token = %RefreshToken{} <- Repo.get_by(RefreshToken, user_id: user.id, account_id: account_id) do
        access_token = generate_access_token(refresh_token)
        {:ok, %{ access_token: access_token, token_type: "bearer", expires_in: 3600, refresh_token: refresh_token.id }}
      else
        nil -> {:error, %{ error: :invalid_scope, error_description: "The scope provided is invalid or not allowed." }}
      end
    else
      {:error, %{ error: :invalid_grant, error_description: "Username and password does not match." }}
    end
  end
  def create_user_account_token(user_global_refresh_token_id, account_id) do
  end
  def create_user_account_token(user_account_refresh_token_id) do

  end

  def create_user_global_token(username, password) do
  end

  def create_user_global_token(refresh_token_id) do
  end




  # Get token using :username and :password
  def create_token(%{ "grant_type" => "password", "username" => username, "password" => password, "scope" => scope }), do: create_token(%{ username: username, password: password, scope: deserialize_scope(scope) })
  def create_token(%{ username: username, password: password, scope: "" <> _ = scope }), do: create_token(%{ username: username, password: password, scope: deserialize_scope(scope) })
  def create_token(%{ username: nil }), do: {:error, %{ error: :invalid_request, error_description: "Email can't be blank." }}
  def create_token(%{ password: nil }), do: {:error, %{ error: :invalid_request, error_description: "Password can't be blank." }}
  def create_token(%{ username: username, password: password, scope: %{ "type" => "user" } = scope }) do
    with {:ok, user} <- get_user(username),
         {:ok, account_id} <- extract_account_id(scope, user),
         true <- Comeonin.Bcrypt.checkpw(password, user.encrypted_password),
         refresh_token <- Repo.get_by!(RefreshToken, user_id: user.id, account_id: account_id)
    do
      access_token = generate_access_token(refresh_token)
      {:ok, %{ access_token: access_token, token_type: "bearer", expires_in: 3600, refresh_token: refresh_token.id }}
    else
      false -> {:error, %{ error: :invalid_grant, error_description: "Username and password does not match." }}
      {:error, :not_found} -> {:error, %{ error: :invalid_grant, error_description: "Username and password does not match." }}
      {:error, :invalid_access_token} -> {:error, %{ error: :invalid_request, error_description: "Access Token is invalid." }}
    end
  end
  def create_token(%{ username: username, password: password, scope: %{ "type" => "customer", "account_id" => account_id } }) do
    with {:ok, _} <- Ecto.UUID.dump(account_id),
         {:ok, customer} <- get_customer(account_id, username),
         true <- Comeonin.Bcrypt.checkpw(password, customer.encrypted_password),
         refresh_token <- Repo.get_by!(RefreshToken, customer_id: customer.id, account_id: account_id)
    do
      access_token = generate_access_token(refresh_token)
      {:ok, %{ access_token: access_token, token_type: "bearer", expires_in: 3600, refresh_token: refresh_token.id }}
    else
      :error -> {:error, %{ error: :invalid_request, error_description: "Access Token is invalid"}}
      {:error, :not_found} -> {:error, %{ error: :invalid_grant, error_description: "Username and password does not match." }}
      false -> {:error, %{ error: :invalid_grant, error_description: "Username and password does not match." }}
      {:error, :invalid_access_token} -> {:error, %{ error: :invalid_request, error_description: "Access Token is invalid." }}
    end
  end
  # Get token using :refresh_token
  def create_token(%{ "grant_type" => "refresh_token", "refresh_token" => refresh_token }), do: create_token(%{ refresh_token: refresh_token })
  def create_token(%{ refresh_token: "" }), do: {:error, %{ error: :invalid_grant, error_description: "refresh_token is invalid, expired or revoked."}}
  def create_token(%{ refresh_token: refresh_token }) do
    with {:ok, _} <- Ecto.UUID.dump(refresh_token),
         {:ok, refresh_token} <- get_refresh_token(refresh_token)
    do
      access_token = generate_access_token(refresh_token)
      {:ok, %{ access_token: access_token, token_type: "bearer", expires_in: 3600, refresh_token: refresh_token.id }}
    else
      :error -> {:error, %{ error: :invalid_grant, error_description: "refresh_token is invalid, expired or revoked."}}
      {:error, :not_found} -> {:error, %{ error: :invalid_grant, error_description: "refresh_token is invalid, expired or revoked."}}
    end
  end
  def create_token(_), do: {:error, %{ error: :invalid_request }}

  def deserialize_scope(scope_string) do
    scopes = String.split(scope_string, ",")
    Enum.reduce(scopes, %{}, fn(scope, acc) ->
      with [key, value] <- String.split(scope, ":") do
        Map.put(acc, String.to_atom(key), value)
      else
        _ -> acc
      end
    end)
  end

  defp generate_access_token(%RefreshToken{ account_id: account_id, user_id: nil }) do
    Jwt.sign_token(%{ exp: System.system_time(:second) + 3600, prn: account_id, typ: "account" })
  end
  defp generate_access_token(%RefreshToken{ account_id: account_id, user_id: user_id }) do
    Jwt.sign_token(%{ exp: System.system_time(:second) + 3600, aud: account_id, prn: user_id, typ: "user" })
  end
  defp generate_access_token(%RefreshToken{ account_id: account_id, user_id: nil }) do
    Jwt.sign_token(%{ exp: System.system_time(:second) + 3600, aud: account_id, typ: "customer" })
  end

  defp extract_account_id(%{ "account_id" => account_id }, _) do
    {:ok, account_id}
  end
  defp extract_account_id(_, %User{ default_account_id: account_id }) do
    {:ok, account_id}
  end

  defp get_refresh_token(id) do
    refresh_token = Repo.get(RefreshToken, id)

    if refresh_token do
      {:ok, refresh_token}
    else
      {:error, :not_found}
    end
  end

  defp get_user(email) do
    user = Repo.get_by(User, email: email)

    if user do
      {:ok, user}
    else
      {:error, :not_found}
    end
  end

  defp get_customer(account_id, email) do
    customer = Repo.get_by(Customer, account_id: account_id, email: email)

    if customer do
      {:ok, customer}
    else
      {:error, :not_found}
    end
  end
end
