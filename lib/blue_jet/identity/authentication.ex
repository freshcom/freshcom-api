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
  %{ "grant_type" => "refresh_token", "refresh_token" => "user-global-refresh-token" }

  Request for User Global Account Access Token
  %{ "grant_type" => "password", "username" => "test1@example.com", "password" => "test1234", "scope" => "account_id:*" }
  %{ "grant_type" => "refresh_token", "refresh_token" => "user-global-access-token" }
  """

  import Ecto.Query

  alias BlueJet.Repo
  alias BlueJet.Identity.User
  alias BlueJet.Identity.Jwt
  alias BlueJet.Identity.RefreshToken

  def create_token(request = %{ "grant_type" => "password", "username" => username, "password" => password, "scope" => scope }) do
    create_token(%{ grant_type: "password", username: username, password: password, scope: deserialize_scope(scope) })
  end
  def create_token(request = %{ "grant_type" => "password", "username" => username, "password" => password }) do
    create_token(%{ grant_type: "password", username: username, password: password })
  end
  def create_token(request = %{ "grant_type" => "refresh_token", "refresh_token" => refresh_token, "scope" => scope }) do
    create_token(%{ grant_type: "password", refresh_token: refresh_token, scope: deserialize_scope(scope) })
  end
  def create_token(request = %{ "grant_type" => "refresh_token", "refresh_token" => refresh_token }) do
    create_token(%{ grant_type: "password", refresh_token: refresh_token })
  end

  def create_token(%{ grant_type: "password", username: username, password: password }) do
    user = User |> User.Query.global() |> Repo.get_by(email: username)
    create_token_by_password(user, password)
  end
  def create_token(%{ grant_type: "password", username: username, password: password, scope: %{ account_id: account_id } }) do
    user = User |> User.Query.member_of_account(account_id) |> Repo.get_by(email: username)
    create_token_by_password(user, password, account_id)
  end
  def create_token(%{ grant_type: "refresh_token", refresh_token: refresh_token_id }) do
    refresh_token = Repo.get(RefreshToken, refresh_token_id)
    create_token_by_refresh_token(refresh_token)
  end
  def create_token(%{ grant_type: "refresh_token", refresh_token: refresh_token_id, scope: %{ account_id: account_id } }) do
    refresh_token = Repo.get(RefreshToken, refresh_token_id)
    create_token_by_refresh_token(refresh_token, account_id)
  end

  # No scope
  def create_token_by_password(nil, password) do
    {:error, %{ error: :invalid_grant, error_description: "Username and password does not match." }}
  end
  def create_token_by_password(%User{ id: user_id, encrypted_password: encrypted_password }, password) do
    if Comeonin.Bcrypt.checkpw(password, encrypted_password) do
      refresh_token = from(rt in RefreshToken, where: is_nil(rt.account_id)) |> Repo.get_by!(user_id: user_id)

      token = Jwt.sign_token(%{ exp: System.system_time(:second) + 3600, prn: user_id, typ: "user" })
      {:ok, %{ access_token: token, token_type: "bearer", expires_in: 3600, refresh_token: refresh_token.id }}
    else
      {:error, %{ error: :invalid_grant, error_description: "Username and password does not match." }}
    end
  end

  @doc """
  This function assume the given user is either `nil` or part of is a member of `account_id`
  """
  def create_token_by_password(nil, password, account_id) do
    {:error, %{ error: :invalid_grant, error_description: "Username and password does not match." }}
  end
  def create_token_by_password(%User{ id: user_id, encrypted_password: encrypted_password }, password, account_id) do
    if Comeonin.Bcrypt.checkpw(password, encrypted_password) do
      refresh_token = Repo.get_by!(RefreshToken, user_id: user_id, account_id: account_id)

      token = Jwt.sign_token(%{ exp: System.system_time(:second) + 3600, aud: account_id, prn: user_id, typ: "user" })
      {:ok, %{ access_token: token, token_type: "bearer", expires_in: 3600, refresh_token: refresh_token.id }}
    else
      {:error, %{ error: :invalid_grant, error_description: "Username and password does not match." }}
    end
  end

  # No scope
  def create_token_by_refresh_token(nil) do
    {:error, %{ error: :invalid_grant, error_description: "Refresh Token is invalid." }}
  end
  def create_token_by_refresh_token(%RefreshToken{ id: refresh_token_id, user_id: nil, account_id: account_id }) when not is_nil(account_id) do
    token = Jwt.sign_token(%{ exp: System.system_time(:second) + 3600, prn: "account_id", typ: "storefront" })
    {:ok, %{ access_token: token, token_type: "bearer", expires_in: 3600, refresh_token: refresh_token_id }}
  end
  def create_token_by_refresh_token(%RefreshToken{ id: refresh_token_id, user_id: user_id, account_id: nil }) when not is_nil(user_id) do
    token = Jwt.sign_token(%{ exp: System.system_time(:second) + 3600, prn: user_id, typ: "user" })
    {:ok, %{ access_token: token, token_type: "bearer", expires_in: 3600, refresh_token: refresh_token_id }}
  end
  def create_token_by_refresh_token(%RefreshToken{ id: refresh_token_id, user_id: user_id, account_id: account_id }) do
    token = Jwt.sign_token(%{ exp: System.system_time(:second) + 3600, aud: account_id, prn: user_id, typ: "user" })
    {:ok, %{ access_token: token, token_type: "bearer", expires_in: 3600, refresh_token: refresh_token_id }}
  end

  # Scoped
  def create_token_by_refresh_token(nil, _) do
    {:error, %{ error: :invalid_grant, error_description: "Refresh Token is invalid." }}
  end
  def create_token_by_refresh_token(%RefreshToken{ id: refresh_token_id, user_id: user_id, account_id: nil }, scope_account_id) when not is_nil(user_id) do
    token = Jwt.sign_token(%{ exp: System.system_time(:second) + 3600, aud: scope_account_id, prn: user_id, typ: "user" })
    {:ok, %{ access_token: token, token_type: "bearer", expires_in: 3600, refresh_token: refresh_token_id }}
  end
  def create_token_by_refresh_token(%RefreshToken{ id: refresh_token_id, user_id: user_id, account_id: account_id }, scope_account_id) when not is_nil(user_id) do
    if account_id == scope_account_id do
      token = Jwt.sign_token(%{ exp: System.system_time(:second) + 3600, aud: account_id, prn: user_id, typ: "user" })
      {:ok, %{ access_token: token, token_type: "bearer", expires_in: 3600, refresh_token: refresh_token_id }}
    else
      {:error, %{ error: :invalid_scope, error_description: "The scope provided is invalid or not allowed." }}
    end
  end

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
end
