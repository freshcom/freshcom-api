defmodule BlueJet.Authentication do
  alias BlueJet.Repo
  alias BlueJet.User
  alias BlueJet.Customer
  alias BlueJet.Jwt
  alias BlueJet.RefreshToken

  # Get token using :username and :password
  def get_token(%{ "grant_type" => "password", "username" => username, "password" => password, "scope" => scope }, vas), do: get_token(%{ username: username, password: password, scope: scope }, vas)
  def get_token(%{ username: nil }, _), do: {:error, %{ error: :invalid_request, error_description: "Email can't be blank" }}
  def get_token(%{ password: nil }, _), do: {:error, %{ error: :invalid_request, error_description: "Password can't be blank" }}
  def get_token(%{ username: username, password: password, scope: "user" = scope }, vas) do
    with {:ok, user} <- get_user(username),
         {:ok, account_id} <- extract_account_id(scope, vas, user),
         true <- Comeonin.Bcrypt.checkpw(password, user.encrypted_password),
         refresh_token <- Repo.get_by!(RefreshToken, user_id: user.id, account_id: account_id)
    do
      access_token = generate_access_token(%{ user_id: user.id, account_id: user.default_account_id })
      {:ok, %{ access_token: access_token, token_type: "bearer", expires_in: 3600, refresh_token: refresh_token.id }}
    else
      false -> {:error, %{ error: :invalid_grant, error_description: "Username and password does not match" }}
      {:error, :not_found} -> {:error, %{ error: :invalid_grant, error_description: "Username and password does not match" }}
      {:error, :invalid_access_token} -> {:error, %{ error: :invalid_client, error_description: "Access Token is invalid" }}
    end
  end
  def get_token(%{ username: username, password: password, scope: "customer" = scope }, %{ account_id: account_id }) do
    with {:ok, _} <- Ecto.UUID.dump(account_id),
         {:ok, customer} <- get_customer(account_id, username),
         true <- Comeonin.Bcrypt.checkpw(password, customer.encrypted_password),
         refresh_token <- Repo.get_by!(RefreshToken, customer_id: customer.id, account_id: account_id)
    do
      access_token = generate_access_token(%{ customer_id: customer.id, account_id: account_id })
      {:ok, %{ access_token: access_token, token_type: "bearer", expires_in: 3600, refresh_token: refresh_token.id }}
    else
      :error -> {:error, %{ error: :invalid_client, error_description: "Access Token is invalid"}}
      {:error, :not_found} -> {:error, %{ error: :invalid_grant, error_description: "Username and password does not match" }}
      false -> {:error, %{ error: :invalid_grant, error_description: "Username and password does not match" }}
      {:error, :invalid_access_token} -> {:error, %{ error: :invalid_client, error_description: "Access Token is invalid" }}
    end
  end
  # Get token using :refresh_token
  def get_token(%{ "grant_type" => "refresh_token", "refresh_token" => refresh_token }, vas), do: get_token(%{ refresh_token: refresh_token }, vas)
  def get_token(%{ refresh_token: "" }, nil), do: {:error, %{ error: :invalid_grant, error_description: "refresh_token is invalid, expired or revoked"}}
  def get_token(%{ refresh_token: refresh_token }, vas) do
    with {:ok, _} <- Ecto.UUID.dump(refresh_token),
         {:ok, %{ account_id: account_id, user_id: user_id } = refresh_token} <- get_refresh_token(refresh_token),
         true <- vas_matches_refresh_token?(vas, refresh_token)
    do
      access_token = generate_access_token(%{ user_id: user_id, account_id: account_id })
      {:ok, %{ access_token: access_token, token_type: "bearer", expires_in: 3600, refresh_token: refresh_token }}
    else
      :error -> {:error, %{ error: :invalid_grant, error_description: "refresh_token is invalid, expired or revoked"}}
      {:error, :not_found} -> {:error, %{ error: :invalid_grant, error_description: "refresh_token is invalid, expired or revoked"}}
      false -> {:error, %{ error: :invalid_client }}
    end
  end
  def get_token(_, _), do: {:error, %{ error: :invalid_request }}

  def vas_matches_refresh_token?(nil, %{ user_id: nil }) do
    true
  end
  def vas_matches_refresh_token?(nil, _) do
    false
  end
  def vas_matches_refresh_token?(%{ account_id: vas_aid, user_id: vas_uid }, %{ account_id: rt_aid, user_id: rt_uid }) do
    vas_aid == rt_aid && vas_uid == rt_uid
  end
  def vas_matches_refresh_token?(%{ account_id: vas_aid }, %{ account_id: rt_aid, user_id: nil }) do
    vas_aid == rt_aid
  end

  def generate_access_token(%{ user_id: nil, account_id: account_id }) do
    Jwt.sign_token(%{ exp: System.system_time(:second) + 3600, prn: account_id, typ: "account" })
  end
  def generate_access_token(%{ user_id: user_id, account_id: account_id }) do
    Jwt.sign_token(%{ exp: System.system_time(:second) + 3600, aud: account_id, prn: user_id, typ: "user" })
  end
  def generate_access_token(%{ customer_id: customer_id, account_id: account_id }) do
    Jwt.sign_token(%{ exp: System.system_time(:second) + 3600, aud: account_id, prn: customer_id, typ: "customer" })
  end

  def extract_account_id("user", nil, %User{ default_account_id: account_id }) do
    {:ok, account_id}
  end
  def extract_account_id("user", %{ account_id: account_id }, _) do
    {:ok, account_id}
  end
  # TODO: support scope: "user,aid:gaeg-awgelk-gwlkejg-aega"
  def extract_account_id(scope, _vas, _user) do
    with ["aid", account_id] <- String.split(scope, ":")
    do
      {:ok, account_id}
    else
      _ -> {:error, :invalid_scope}
    end
  end

  def get_refresh_token(refresh_token) do
    refresh_token = Repo.get(RefreshToken, refresh_token)

    if refresh_token do
      {:ok, refresh_token}
    else
      {:error, :not_found}
    end
  end

  def get_user(email) do
    user = Repo.get_by(User, email: email)

    if user do
      {:ok, user}
    else
      {:error, :not_found}
    end
  end

  def get_customer(account_id, email) do
    customer = Repo.get_by(Customer, account_id: account_id, email: email)

    if customer do
      {:ok, customer}
    else
      {:error, :not_found}
    end
  end
end
