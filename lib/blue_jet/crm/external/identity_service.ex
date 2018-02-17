defmodule BlueJet.Crm.IdentityService do
  alias BlueJet.Identity.{User, Account}

  @identity_service Application.get_env(:blue_jet, :crm)[:identity_service]

  @callback get_account(String.t | map) :: Account.t | nil
  @callback create_user(map, map) :: {:ok, User.t} | {:error, any}
  @callback delete_user(String.t, map) :: {:ok, User.t} | {:error, any}

  defdelegate get_account(id_or_struct), to: @identity_service
  defdelegate create_user(fields, opts), to: @identity_service
  defdelegate delete_user(id, opts), to: @identity_service
end