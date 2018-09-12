defmodule BlueJet.Identity.Authentication do
  use BlueJet.EventEmitter, namespace: :identity
  alias BlueJet.Identity.Service

  @token_expiry_seconds 3600
  @errors [
    invalid_password_grant: {:error, %{error: :invalid_grant, error_description: "Username and password does not match."}},
    invalid_refresh_token_grant: {:error, %{error: :invalid_grant, error_description: "Refresh token is invalid."}},
    invalid_otp: {:error, %{error: :invalid_otp, error_description: "OTP is invalid."}}
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

  def create_token(%{"grant_type" => grant_type}) when grant_type not in ["refresh_token", "password"] do
    {:error, %{error: :unsupported_grant_type, error_description: "\"grant_type\" must be one of \"password\" or \"refresh_token\""}}
  end

  def create_token(%{"grant_type" => "password", "scope" => scope} = fields) do
    scope = deserialize_scope(scope, %{aid: :account_id})
    fields =
      fields
      |> take_atomize(["grant_type", "username", "password"])
      |> Map.merge(%{otp: fields["otp"]})
      |> Map.merge(%{scope: scope})

    create_token_by_password(fields)
  end

  def create_token(%{"grant_type" => "password"} = fields) do
    fields =
      fields
      |> take_atomize(["grant_type", "username", "password"])
      |> Map.merge(%{otp: fields["otp"]})

    create_token_by_password(fields)
  end

  def create_token(%{"grant_type" => "refresh_token", "scope" => scope} = fields) do
    scope = deserialize_scope(scope, %{aid: :account_id})
    fields =
      fields
      |> take_atomize(["grant_type", "refresh_token"])
      |> Map.merge(%{scope: scope})

    create_token_by_refresh_token(fields)
  end

  def create_token(%{"grant_type" => "refresh_token", "refresh_token" => refresh_token}) do
    create_token_by_refresh_token(%{grant_type: "refresh_token", refresh_token: refresh_token})
  end

  defp take_atomize(m, keys) do
    m
    |> Map.take(keys)
    |> Enum.reduce(%{}, fn({k, v}, acc) -> Map.put(acc, String.to_atom(k), v) end)
  end

  def create_token_by_password(%{username: username, password: password, scope: scope} = fields) do
    case Repo.get(Account, scope[:account_id]) do
      nil ->
        nil

      account ->
        user = Service.get_user(%{username: username}, %{account: account})
        do_create_token_by_password(user, password, fields[:otp], scope[:account_id])
    end
  rescue
    Ecto.Query.CastError ->
      @errors[:invalid_password_grant]
  end

  def create_token_by_password(%{username: username, password: password} = fields) do
    user = Repo.get_by(User, username: username)

    if user && User.type(user) == :managed && User.get_role(user, user.account_id) == "customer" do
      @errors[:invalid_password_grant]
    else
      do_create_token_by_password(user, password, fields[:otp])
    end
  end

  def create_token_by_password(_) do
    {:error, %{error: :invalid_request, error_description: "Your request is missing required parameters or is otherwise malformed."}}
  end

  def create_token_by_refresh_token(%{refresh_token: refresh_token_id, scope: scope}) do
    target_account = Repo.get!(Account, scope[:account_id])
    refresh_token = Repo.get(RefreshToken, RefreshToken.unprefix_id(refresh_token_id))

    cond do
      refresh_token.account_id == scope[:account_id] ->
        do_create_token_by_refresh_token(refresh_token)

      refresh_token.account_id == target_account.live_account_id ->
        target_refresh_token =
          Repo.get_by(RefreshToken, account_id: target_account.id, user_id: refresh_token.user_id)

        do_create_token_by_refresh_token(target_refresh_token)

      true ->
        do_create_token_by_refresh_token(nil)
    end
  rescue
    Ecto.Query.CastError ->
      @errors[:invalid_refresh_token_grant]
  end

  def create_token_by_refresh_token(%{refresh_token: refresh_token_id}) do
    refresh_token = Repo.get(RefreshToken, RefreshToken.unprefix_id(refresh_token_id))
    do_create_token_by_refresh_token(refresh_token)
  rescue
    Ecto.Query.CastError ->
      @errors[:invalid_password_grant]
  end

  def create_token_by_refresh_token(_) do
    {:error, %{error: :invalid_request, error_description: "Your request is missing required parameters or is otherwise malformed."}}
  end

  defp do_create_token_by_password(nil, _, _) do
    @errors[:invalid_password_grant]
  end

  defp do_create_token_by_password(user, password, otp) do
    do_create_token_by_password(user, password, otp, user.default_account_id)
  end

  defp do_create_token_by_password(nil, _, _, _) do
    @errors[:invalid_password_grant]
  end

  defp do_create_token_by_password(user, password, otp, account_id) do
    password_valid = Comeonin.Bcrypt.checkpw(password, user.encrypted_password)
    otp_provided = otp != "" && otp
    otp_valid = User.is_tfa_code_valid?(user, otp)

    cond do
      password_valid && otp_valid ->
        refresh_token = Repo.get_by!(RefreshToken, user_id: user.id, account_id: account_id)
        Repo.update!(User.changeset(user, :clear_tfa_code))
        do_create_token_by_refresh_token(refresh_token)

      !password_valid ->
        @errors[:invalid_password_grant]

      !otp_provided ->
        Repo.update!(User.changeset(user, :refresh_tfa_code))
        BlueJet.EventBus.dispatch("identity:user.tfa_code.create.success", %{user: user})
        @errors[:invalid_otp]

      !otp_valid ->
        @errors[:invalid_otp]
    end
  end

  defp do_create_token_by_refresh_token(nil) do
    @errors[:invalid_refresh_token_grant]
  end

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

  def deserialize_scope(scope_string, abr_mappings \\ %{}) do
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
end
