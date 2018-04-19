defmodule BlueJet.Identity.Service do
  @service Application.get_env(:blue_jet, :identity)[:service]

  @callback get_vas_data(map) :: map
  @callback get_account(map | String.t) :: Account.t | nil
  @callback create_account(map) :: {:ok, Account.t} | {:error, any}
  @callback update_account(Account.t, map, map) :: {:ok, Account.t} | {:error, any}
  @callback reset_account(Account.t) :: {:ok, Account.t} | {:error, any}

  @callback create_user(map, map) :: {:ok, User.t} | {:error, any}
  @callback get_user(map, map) :: User.t | nil
  @callback update_user(String.t | User.t, map, map) :: {:ok, User.t} | {:error, any}
  @callback delete_user(String.t | User.t, map) :: {:ok, User.t} | {:error, any}

  @callback create_email_verification_token(User.t) :: {:ok, User.t} | {:error, any}
  @callback create_email_verification_token(map, map) :: {:ok, User.t} | {:error, any}

  @callback create_email_verification(User.t) :: {:ok, User.t} | {:error, any}
  @callback create_email_verification(map, map) :: {:ok, User.t} | {:error, any}

  @callback create_password_reset_token(String.t, map) :: {:ok, User.t} | {:error, any}

  @callback update_password(Password.t, String.t) :: {:ok, User.t} | {:error, any}
  @callback update_password(map, String.t, map) :: {:ok, User.t} | {:error, any}

  @callback create_phone_verification_code(map, map) :: {:ok, PhoneVerificationCode.t} | {:error, any}

  @callback get_refresh_token(map) :: {:ok, RefreshToken.t} | {:error, any}

  defdelegate get_vas_data(map), to: @service
  defdelegate get_account(id_or_struct), to: @service
  defdelegate create_account(fields), to: @service
  defdelegate update_account(account, fields, opts), to: @service
  defdelegate reset_account(account), to: @service

  defdelegate create_user(fields, opts), to: @service
  defdelegate get_user(fields, opts), to: @service
  defdelegate update_user(id_or_user, fields, opts), to: @service
  defdelegate delete_user(id_or_user, opts), to: @service

  defdelegate create_email_verification_token(user), to: @service
  defdelegate create_email_verification_token(fields, opts), to: @service

  defdelegate create_email_verification(user), to: @service
  defdelegate create_email_verification(fields, opts), to: @service

  defdelegate create_password_reset_token(email, opts), to: @service

  defdelegate update_password(password, new_password), to: @service
  defdelegate update_password(identifiers, new_password, opts), to: @service

  defdelegate create_phone_verification_code(fields, opts), to: @service

  defdelegate get_refresh_token(opts), to: @service
end