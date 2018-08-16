defmodule BlueJet.Identity.Authentication do
  use BlueJet.EventEmitter, namespace: :identity

  @token_expiry_seconds 3600
  @errors [
    invalid_password_grant: {:error, %{error: :invalid_grant, error_description: "Username and password does not match."}},
    invalid_refresh_token_grant: {:error, %{error: :invalid_grant, error_description: "Refresh token is invalid."}}
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

  def create_token(
        fields = %{
          "grant_type" => "password",
          "username" => username,
          "password" => password,
          "scope" => scope
        }
      ) do
    create_token(%{
      grant_type: "password",
      username: username,
      password: password,
      otp: fields["otp"],
      scope: deserialize_scope(scope, %{aid: :account_id})
    })
  end

  def create_token(
        fields = %{"grant_type" => "password", "username" => username, "password" => password}
      ) do
    create_token(%{
      grant_type: "password",
      username: username,
      password: password,
      otp: fields["otp"]
    })
  end

  def create_token(%{
        "grant_type" => "refresh_token",
        "refresh_token" => refresh_token,
        "scope" => scope
      }) do
    create_token(%{
      grant_type: "refresh_token",
      refresh_token: refresh_token,
      scope: deserialize_scope(scope, %{aid: :account_id})
    })
  end

  def create_token(%{"grant_type" => "refresh_token", "refresh_token" => refresh_token}) do
    create_token(%{grant_type: "refresh_token", refresh_token: refresh_token})
  end

  def create_token(
        fields = %{
          grant_type: "password",
          username: username,
          password: password,
          scope: %{account_id: account_id}
        }
      ) do
    account = Repo.get(Account, account_id)

    user = case account.mode do
      "test" ->
        test_user =
          User
          |> User.Query.member_of_account(account_id)
          |> Repo.get_by(username: username)

        test_user ||
        User
        |> User.Query.member_of_account(account.live_account_id)
        |> Repo.get_by(username: username)

      "live" ->
        User
        |> User.Query.member_of_account(account_id)
        |> Repo.get_by(username: username)
    end

    create_token_by_password(user, password, fields[:otp], account_id)
  rescue
    Ecto.Query.CastError ->
      @errors[:invalid_password_grant]
  end

  def create_token(fields = %{grant_type: "password", username: username, password: password}) do
    user = Repo.get_by(User, username: username)

    if user && User.is_managed_user?(user) && User.get_role(user, user.account_id) == "customer" do
      @errors[:invalid_password_grant]
    else
      create_token_by_password(user, password, fields[:otp])
    end
  end

  def create_token(%{
        grant_type: "refresh_token",
        refresh_token: refresh_token_id,
        scope: %{account_id: account_id}
      }) do
    target_account = Repo.get!(Account, account_id)
    refresh_token = Repo.get(RefreshToken, RefreshToken.unprefix_id(refresh_token_id))

    cond do
      refresh_token.account_id == account_id ->
        create_token_by_refresh_token(refresh_token)

      refresh_token.account_id == target_account.live_account_id ->
        target_refresh_token =
          Repo.get_by(RefreshToken, account_id: target_account.id, user_id: refresh_token.user_id)

        create_token_by_refresh_token(target_refresh_token)

      true ->
        create_token_by_refresh_token(nil)
    end
  rescue
    Ecto.Query.CastError ->
      @errors[:invalid_refresh_token_grant]
  end

  def create_token(%{grant_type: "refresh_token", refresh_token: refresh_token_id}) do
    refresh_token = Repo.get(RefreshToken, RefreshToken.unprefix_id(refresh_token_id))
    create_token_by_refresh_token(refresh_token)
  rescue
    Ecto.Query.CastError ->
      @errors[:invalid_password_grant]
  end

  def create_token(_) do
    {:error, %{error: :invalid_request, error_description: "Your request is missing required parameters or is otherwise malformed."}}
  end

  # No scope
  defp create_token_by_password(nil, _, _) do
    @errors[:invalid_password_grant]
  end

  defp create_token_by_password(user, password, otp) do
    password_valid = Comeonin.Bcrypt.checkpw(password, user.encrypted_password)
    otp_provided = otp != "" && otp

    otp_valid =
      user.auth_method == "simple" ||
        (user.auth_method == "tfa_sms" && otp && otp == User.get_tfa_code(user))

    cond do
      password_valid && otp_valid ->
        refresh_token =
          user.id
          |> RefreshToken.Query.for_user()
          |> Repo.get_by!(account_id: user.default_account_id)

        User.clear_tfa_code(user)

        token =
          Jwt.sign_token(%{
            exp: System.system_time(:second) + @token_expiry_seconds,
            aud: user.default_account_id,
            prn: user.id,
            typ: "user"
          })

        {:ok,
         %{
           access_token: token,
           token_type: "bearer",
           expires_in: @token_expiry_seconds,
           refresh_token: RefreshToken.get_prefixed_id(refresh_token)
         }}

      !password_valid ->
        {:error,
         %{error: :invalid_grant, error_description: "Username and password does not match."}}

      !otp_provided ->
        user = User.refresh_tfa_code(user)
        emit_event("identity.user.tfa_code.create.success", %{account: nil, user: user})
        {:error, %{error: :invalid_otp, error_description: "OTP is invalid."}}

      !otp_valid ->
        {:error, %{error: :invalid_otp, error_description: "OTP is invalid."}}
    end
  end

  defp create_token_by_password(nil, _, _, _) do
    @errors[:invalid_password_grant]
  end

  defp create_token_by_password(user, password, otp, account_id) do
    password_valid = Comeonin.Bcrypt.checkpw(password, user.encrypted_password)
    otp_provided = otp != "" && otp

    otp_valid =
      user.auth_method == "simple" ||
        (user.auth_method == "tfa_sms" && otp && otp == User.get_tfa_code(user))

    cond do
      password_valid && otp_valid ->
        refresh_token =
          user.id
          |> RefreshToken.Query.for_user()
          |> Repo.get_by!(account_id: account_id)

        User.clear_tfa_code(user)

        token =
          Jwt.sign_token(%{
            exp: System.system_time(:second) + @token_expiry_seconds,
            aud: account_id,
            prn: user.id,
            typ: "user"
          })

        {:ok,
         %{
           access_token: token,
           token_type: "bearer",
           expires_in: @token_expiry_seconds,
           refresh_token: RefreshToken.get_prefixed_id(refresh_token)
         }}

      !password_valid ->
        @errors[:invalid_password_grant]

      !otp_provided ->
        user = User.refresh_tfa_code(user)
        account = Repo.get!(Account, account_id)
        emit_event("identity.user.tfa_code.create.success", %{account: account, user: user})
        {:error, %{error: :invalid_otp, error_description: "OTP is invalid."}}

      !otp_valid ->
        {:error, %{error: :invalid_otp, error_description: "OTP is invalid."}}
    end
  end

  defp create_token_by_refresh_token(nil) do
    @errors[:invalid_refresh_token_grant]
  end

  defp create_token_by_refresh_token(
         refresh_token = %RefreshToken{user_id: nil, account_id: account_id}
       )
       when not is_nil(account_id) do
    token =
      Jwt.sign_token(%{
        exp: System.system_time(:second) + @token_expiry_seconds,
        prn: account_id,
        typ: "publishable"
      })

    {:ok,
     %{
       access_token: token,
       token_type: "bearer",
       expires_in: @token_expiry_seconds,
       refresh_token: RefreshToken.get_prefixed_id(refresh_token)
     }}
  end

  defp create_token_by_refresh_token(
         refresh_token = %RefreshToken{user_id: user_id, account_id: account_id}
       ) do
    token =
      Jwt.sign_token(%{
        exp: System.system_time(:second) + @token_expiry_seconds,
        aud: account_id,
        prn: user_id,
        typ: "user"
      })

    {:ok,
     %{
       access_token: token,
       token_type: "bearer",
       expires_in: @token_expiry_seconds,
       refresh_token: RefreshToken.get_prefixed_id(refresh_token)
     }}
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
