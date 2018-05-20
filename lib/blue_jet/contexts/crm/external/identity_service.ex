defmodule BlueJet.Crm.IdentityService do
  alias BlueJet.Identity.{User, Account}

  @identity_service Application.get_env(:blue_jet, :crm)[:identity_service]

  @callback put_vas_data(map) :: map
  @callback get_account(String.t | map) :: Account.t | nil
  @callback create_user(map, map) :: {:ok, User.t} | {:error, any}
  @callback update_user(String.t | User.t, map, map) :: {:ok, User.t} | {:error, any}
  @callback delete_user(String.t, map) :: {:ok, User.t} | {:error, any}

  defdelegate put_vas_data(request), to: @identity_service
  defdelegate get_account(id_or_struct), to: @identity_service
  defdelegate create_user(fields, opts), to: @identity_service
  defdelegate update_user(id_or_user, fields, opts), to: @identity_service
  defdelegate delete_user(id, opts), to: @identity_service
end