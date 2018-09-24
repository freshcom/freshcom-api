defmodule BlueJet.Identity.Authentication.Service do
  import BlueJet.ControlFlow
  import BlueJet.Identity.User.Service, only: [get_user: 2]
  alias BlueJet.EventBus

  @token_expiry_seconds 3600
  @errors [
    invalid_password_grant: {:error, %{error: :invalid_grant, error_description: "Username and password does not match."}},
    invalid_refresh_token_grant: {:error, %{error: :invalid_grant, error_description: "Refresh token is invalid."}},
    invalid_otp: {:error, %{error: :invalid_otp, error_description: "OTP is invalid."}},
    invalid_request: {:error, %{error: :invalid_request, error_description: "Your request is missing required parameters or is otherwise malformed."}}
  ]

  @moduledoc """
  Publishable Refresh Token
  %{ user_id: nil, account_id: "test-test-test-test" }

  User Refresh Token
  %{ user_id: "test-test-test-test", account_id: "test-test-test-test" }

  Publishable Access Token
  %{ exp: 3600, aud: "", prn: "test-test-test-test", typ: "publishable" }

  User Access Token
  %{ exp: 3600, aud: "account-id", prn": "user-id", typ: "user" }

  Request for Publishable Access Token
  %{ "grant_type" => "refresh_token", "refresh_token" => "publishable-refresh-token" }

  Request for User Access Token
  %{ "grant_type" => "password", "username" => "test1@example.com", "password" => "test1234", "scope" => "account_id:test-test-test-test" }
  %{ "grant_type" => "password", "username" => "test1@example.com", "password" => "test1234" }
  %{ "grant_type" => "refresh_token", "refresh_token" => "user-refresh-token" }
  """

  alias BlueJet.Repo
  alias BlueJet.Identity.{User, Account, Jwt, RefreshToken}

  def create_access_token(%{"grant_type" => grant_type}) when grant_type not in ["refresh_token", "password"] do
    {:error, %{error: :unsupported_grant_type, error_description: "\"grant_type\" must be one of \"password\" or \"refresh_token\""}}
  end

  def create_access_token(%{"grant_type" => "password", "scope" => scope} = fields) do
    scope = deserialize_scope(scope, %{aid: :account_id})

    fields
    |> take_atomize(["grant_type", "username", "password", "otp"])
    |> Map.merge(%{scope: scope})
    |> create_token_by_password()
  end

  def create_access_token(%{"grant_type" => "password"} = fields) do
    fields
    |> take_atomize(["grant_type", "username", "password", "otp"])
    |> create_token_by_password()
  end

  def create_access_token(%{"grant_type" => "refresh_token", "scope" => scope} = fields) do
    scope = deserialize_scope(scope, %{aid: :account_id})

    fields
    |> take_atomize(["grant_type", "refresh_token"])
    |> Map.merge(%{scope: scope})
    |> create_token_by_refresh_token()
  end

  def create_access_token(%{"grant_type" => "refresh_token", "refresh_token" => refresh_token}) do
    create_token_by_refresh_token(%{grant_type: "refresh_token", refresh_token: refresh_token})
  end

  def create_access_token(_), do: @errors[:invalid_request]

  defp deserialize_scope(scope_string, abr_mappings) do
    scopes = String.split(scope_string, ",")

    Enum.reduce(scopes, %{}, fn scope, acc ->
      with [key, value] <- String.split(scope, ":") do
        raw_key = String.to_atom(key)
        key = abr_mappings[raw_key] || raw_key
        Map.put(acc, key, value)
      else
        _ -> acc
      end
    end)
  end

  defp take_atomize(m, keys) do
    m
    |> Map.take(keys)
    |> Enum.reduce(%{}, fn({k, v}, acc) -> Map.put(acc, String.to_atom(k), v) end)
  end

  defp create_token_by_password(%{username: username, password: password, scope: scope} = fields) do
    {:ok, Account}
    ~>  Repo.get(scope[:account_id] || Ecto.UUID.generate())
    ~>> get_user_for_token(username)
    ~>> do_create_token_by_password(password, fields[:otp], scope[:account_id])
    |>  normalize_tt()
  rescue
    Ecto.Query.CastError ->
      @errors[:invalid_password_grant]
  end

  defp create_token_by_password(%{username: username, password: password} = fields) do
    get_user_for_token(username)
    ~>> do_create_token_by_password(password, fields[:otp])
    |>  normalize_tt()
  end

  defp create_token_by_password(_) do
    {:error, %{error: :invalid_request, error_description: "Your request is missing required parameters or is otherwise malformed."}}
  end

  defp get_user_for_token(account, username) do
    %{"username" => username}
    |> get_user(%{account: account, type: :managed})
    |> tt()
  end

  defp get_user_for_token(username) do
    %{"username" => username}
    |> get_user(%{account: nil})
    |> tt()
  end

  defp normalize_tt({:error, nil}), do: @errors[:invalid_password_grant]
  defp normalize_tt({:error, reason}), do: {:error, reason}
  defp normalize_tt({:ok, token}), do: {:ok, token}

  defp do_create_token_by_password(nil, _, _) do
    @errors[:invalid_password_grant]
  end

  defp do_create_token_by_password(user, password, otp) do
    do_create_token_by_password(user, password, otp, user.default_account_id)
  end

  defp do_create_token_by_password(nil, _, _, _) do
    @errors[:invalid_password_grant]
  end

  defp do_create_token_by_password(%{auth_method: "simple"} = user, password, _, account_id) do
    user
    |>  check_password(password)
    ~>> get_refresh_token(account_id)
    ~>> do_create_token_by_refresh_token()
  end

  defp do_create_token_by_password(user, password, nil, _) do
    user
    |>  check_password(password)
    ~> refresh_tfa_code()
    ~>> dispatch("identity:user.tfa_code.create.success")

    @errors[:invalid_otp]
  end

  defp do_create_token_by_password(user, password, otp, account_id) do
    user
    |>  check_password(password)
    ~>> check_otp(otp)
    ~>> clear_tfa_code()
    ~>> get_refresh_token(account_id)
    ~>> do_create_token_by_refresh_token()
  end

  defp check_password(user, password) do
    if User.is_password_valid?(user, password) do
      {:ok, user}
    else
      @errors[:invalid_password_grant]
    end
  end

  defp check_otp(user, otp) do
    if User.is_tfa_code_valid?(user, otp) do
      {:ok, user}
    else
      @errors[:invalid_otp]
    end
  end

  defp get_refresh_token(user, account_id) do
    RefreshToken
    |> Repo.get_by!(user_id: user.id, account_id: account_id)
    |> tt()
  end

  defp clear_tfa_code(user) do
    user
    |> User.changeset(:clear_tfa_code)
    |> Repo.update!()
    |> tt()
  end

  defp dispatch(user, event_name) do
    EventBus.dispatch(event_name, %{user: user})
  end

  defp create_token_by_refresh_token(%{refresh_token: refresh_token_id, scope: scope}) do
    target_account = Repo.get!(Account, scope[:account_id])
    refresh_token = Repo.get(RefreshToken, RefreshToken.unprefix_id(refresh_token_id))

    cond do
      refresh_token.account_id == scope[:account_id] ->
        do_create_token_by_refresh_token(refresh_token)

      refresh_token.account_id == target_account.live_account_id ->
        RefreshToken
        |> Repo.get_by(account_id: target_account.id, user_id: refresh_token.user_id)
        |> do_create_token_by_refresh_token()

      true ->
        @errors[:invalid_refresh_token_grant]
    end
  rescue
    Ecto.Query.CastError ->
      @errors[:invalid_refresh_token_grant]
  end

  defp create_token_by_refresh_token(%{refresh_token: refresh_token_id}) do
    RefreshToken
    |> Repo.get(RefreshToken.unprefix_id(refresh_token_id))
    |> do_create_token_by_refresh_token()
  rescue
    Ecto.Query.CastError ->
      @errors[:invalid_password_grant]
  end

  defp create_token_by_refresh_token(_) do
    @errors[:invalid_request]
  end

  defp do_create_token_by_refresh_token(nil), do: @errors[:invalid_refresh_token_grant]

  defp do_create_token_by_refresh_token(%RefreshToken{user_id: nil} = refresh_token) do
    jwt = Jwt.sign_token(%{
      exp: System.system_time(:second) + @token_expiry_seconds,
      prn: refresh_token.account_id,
      typ: "publishable"
    })
    token = %{
      access_token: jwt,
      token_type: "bearer",
      expires_in: @token_expiry_seconds,
      refresh_token: RefreshToken.get_prefixed_id(refresh_token)
    }

    {:ok, token}
  end

  defp do_create_token_by_refresh_token(%RefreshToken{user_id: user_id} = refresh_token) do
    jwt = Jwt.sign_token(%{
      exp: System.system_time(:second) + @token_expiry_seconds,
      aud: refresh_token.account_id,
      prn: user_id,
      typ: "user"
    })
    token = %{
      access_token: jwt,
      token_type: "bearer",
      expires_in: @token_expiry_seconds,
      refresh_token: RefreshToken.get_prefixed_id(refresh_token)
    }

    {:ok, token}
  end

  def refresh_tfa_code(user) do
    user
    |> User.changeset(:refresh_tfa_code)
    |> Repo.update!()
  end
end
