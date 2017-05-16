defmodule BlueJet.Authentication do
  alias BlueJet.Repo
  alias BlueJet.User
  alias BlueJet.Jwt
  alias BlueJet.RefreshToken

  def get_token(%{ "grant_type" => "password", "username" => username, "password" => password, "scope" => scope }, access_token), do: get_token(%{ username: username, password: password, scope: scope }, access_token)
  def get_token(%{ "grant_type" => "password", "username" => username, "password" => password }, access_token), do: get_token(%{ username: username, password: password, scope: nil }, access_token)
  def get_token(%{ "grant_type" => "refresh_token", "refresh_token" => refresh_token }, access_token), do: get_token(%{ refresh_token: refresh_token }, access_token)
  def get_token(%{ username: nil }, _), do: {:error, %{ error: :invalid_request, error_description: "Email can't be blank" }}
  def get_token(%{ password: nil }, _), do: {:error, %{ error: :invalid_request, error_description: "Password can't be blank" }}
  def get_token(%{ username: username, password: password, scope: scope }, access_token) do
    with {:ok, user} <- get_user(username),
         {:ok, account_id} <- extract_account_id(scope, access_token, user),
         true <- Comeonin.Bcrypt.checkpw(password, user.encrypted_password),
         refresh_token <- Repo.get_by!(RefreshToken, user_id: user.id, account_id: account_id)
    do
      access_token = generate_access_token(%{ user_id: user.id, account_id: user.default_account_id })
      {:ok, %{ access_token: access_token, token_type: "bearer", expires_in: 3600, refresh_token: refresh_token }}
    else
      false -> {:error, %{ error: :invalid_grant, error_description: "Username and password does not match" }}
      {:error, :not_found} -> {:error, %{ error: :invalid_grant, error_description: "Username and password does not match" }}
      {:error, :invalid_access_token} -> {:error, %{ error: :invalid_client, error_description: "Access Token is invalid" }}
    end
  end
  def get_token(%{ username: username, password: password }, access_token), do: get_token(%{ username: username, password: password, scope: nil }, access_token)
  def get_token(%{ refresh_token: "" }, nil), do: {:error, %{ error: :invalid_grant, error_description: "refresh_token is invalid, expired or revoked"}}
  def get_token(%{ refresh_token: refresh_token }, access_token) do
    with {:ok, _} <- Ecto.UUID.dump(refresh_token),
         {:ok, %RefreshToken{ account_id: account_id, user_id: user_id }} <- get_refresh_token(refresh_token),
         {:ok, _} <- verify_access_token_for_refresh(access_token, %{ account_id: account_id, user_id: user_id })
    do
      access_token = generate_access_token(%{ user_id: user_id, account_id: account_id })
      {:ok, %{ access_token: access_token, token_type: "bearer", expires_in: 3600, refresh_token: refresh_token }}
    else
      :error -> {:error, %{ error: :invalid_grant, error_description: "refresh_token is invalid, expired or revoked"}}
      {:error, :not_found} -> {:error, %{ error: :invalid_grant, error_description: "refresh_token is invalid, expired or revoked"}}
      {:error, :invalid} -> {:error, %{ error: :invalid_client }}
      {:error, :expired} -> {:error, %{ error: :invalid_client }}
    end
  end
  def get_token(_, _), do: {:error, %{ error: :invalid_request }}

  def verify_access_token_for_refresh(nil, %{ user_id: nil }) do
    {:ok, nil}
  end
  def verify_access_token_for_refresh(access_token, %{ user_id: nil, account_id: account_id }) do
    with {true, %{ "prn" => prn, "exp" => exp }} <- Jwt.verify_token(access_token),
         true <- exp >= System.system_time(:second),
         true <- prn == account_id
    do
      {:ok, access_token}
    else
      {false, _} -> {:error, :invalid}
      false -> {:error, :invalid}
    end
  end
  def verify_access_token_for_refresh(access_token, %{ user_id: user_id, account_id: account_id }) do
    with {true, %{ "aud" => aud, "prn" => prn, "exp" => exp }} <- Jwt.verify_token(access_token),
         true <- (aud == account_id && prn == user_id),
         true <- (exp >= System.system_time(:second))
    do
      {:ok, access_token}
    else
      {false, _} -> {:error, :invalid}
      false -> {:error, :invalid}
    end
  end

  def generate_access_token(%{ user_id: nil, account_id: account_id }) do
    Jwt.sign_token(%{ exp: System.system_time(:second) + 3600, prn: account_id })
  end
  def generate_access_token(%{ user_id: user_id, account_id: account_id }) do
    Jwt.sign_token(%{ exp: System.system_time(:second) + 3600, aud: account_id, prn: user_id })
  end

  def extract_account_id(nil, nil, %User{ default_account_id: account_id }) do
    {:ok, account_id}
  end
  def extract_account_id(nil, access_token, _) do
    with {true, claims} <- Jwt.verify_token(access_token),
         nil <- Map.get(claims, "aud"), # Account Access Token must not have aud claims
         true <- Map.get(claims, "exp") >= System.system_time(:second)
    do
      {:ok, Map.get(claims, "prn")}
    else
      {false, _} -> {:error, :invalid_access_token}
      false -> {:error, :invalid_access_token}
      aud -> {:error, :invalid_access_token}
    end
  end
  def extract_account_id(scope, _, _) do
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


end
