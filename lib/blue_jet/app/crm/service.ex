defmodule BlueJet.Crm.Service do
  @service Application.get_env(:blue_jet, :crm)[:service]

  @callback list_customer(map, map) :: [Customer.t()]
  @callback count_customer(map, map) :: integer
  @callback create_customer(map, map) :: {:ok, Customer.t()} | {:error, any}
  @callback get_customer(map, map) :: Customer.t() | nil
  @callback update_customer(String.t() | Customer.t(), map, map) ::
              {:ok, Customer.t()} | {:error, any}
  @callback delete_customer(Strint.t() | Customer.t(), map) :: {:ok, Customer.t()} | {:error, any}
  @callback delete_all_customer(map) :: :ok

  @callback get_point_account(map, map) :: PointAccount.t() | nil

  @callback list_point_transaction(map, map) :: [PointTransaction.t()]
  @callback count_point_transaction(map, map) :: integer
  @callback create_point_transaction(map, map) :: {:ok, PointTransaction.t()} | {:error, any}
  @callback get_point_transaction(map, map) :: PointTransaction.t() | nil
  @callback update_point_transaction(String.t() | PointTransaction.t(), map, map) ::
              {:ok, PointTransaction.t()} | {:error, any}
  @callback delete_point_transaction(Strint.t() | PointTransaction.t(), map) ::
              {:ok, PointTransaction.t()} | {:error, any}

  defdelegate list_customer(params \\ %{}, opts), to: @service
  defdelegate count_customer(params \\ %{}, opts), to: @service
  defdelegate create_customer(fields, opts), to: @service
  defdelegate get_customer(identifiers, opts), to: @service
  defdelegate update_customer(id_or_customer, fields, opts), to: @service
  defdelegate delete_customer(id_or_customer, opts), to: @service
  defdelegate delete_all_customer(opts), to: @service

  defdelegate get_point_account(identifiers, opts), to: @service

  defdelegate list_point_transaction(params \\ %{}, opts), to: @service
  defdelegate count_point_transaction(params \\ %{}, opts), to: @service
  defdelegate create_point_transaction(fields, opts), to: @service
  defdelegate get_point_transaction(identifiers, opts), to: @service
  defdelegate update_point_transaction(id_or_point_transaction, fields, opts), to: @service
  defdelegate delete_point_transaction(id_or_point_transaction, opts), to: @service
end
