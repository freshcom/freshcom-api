defmodule BlueJet.Goods.Service do
  @service Application.get_env(:blue_jet, :goods)[:service]

  @callback list_stockable(map, map) :: [Stockable.t]
  @callback count_stockable(map, map) :: integer
  @callback create_stockable(map, map) :: {:ok, Stockable.t} | {:error, any}
  @callback get_stockable(map, map) :: Stockable.t | nil
  @callback update_stockable(String.t | Stockable.t, map, map) :: {:ok, Stockable.t} | {:error, any}
  @callback delete_stockable(String.t | Stockable.t, map) :: {:ok, Stockable.t} | {:error, any}
  @callback delete_all_stockable(map) :: :ok

  @callback list_unlockable(map, map) :: [Unlockable.t]
  @callback count_unlockable(map, map) :: integer
  @callback create_unlockable(map, map) :: {:ok, Unlockable.t} | {:error, any}
  @callback get_unlockable(map, map) :: Unlockable.t | nil
  @callback update_unlockable(String.t | Unlockable.t, map, map) :: {:ok, Unlockable.t} | {:error, any}
  @callback delete_unlockable(String.t | Unlockable.t, map) :: {:ok, Unlockable.t} | {:error, any}
  @callback delete_all_unlockable(map) :: :ok

  @callback list_depositable(map, map) :: [Depositable.t]
  @callback count_depositable(map, map) :: integer
  @callback create_depositable(map, map) :: {:ok, Depositable.t} | {:error, any}
  @callback get_depositable(map, map) :: Depositable.t | nil
  @callback update_depositable(String.t | Depositable.t, map, map) :: {:ok, Depositable.t} | {:error, any}
  @callback delete_depositable(String.t | Depositable.t, map) :: {:ok, Depositable.t} | {:error, any}
  @callback delete_all_depositable(map) :: :ok

  defdelegate list_stockable(params, opts), to: @service
  defdelegate count_stockable(params \\ %{}, opts), to: @service
  defdelegate create_stockable(fields, opts), to: @service
  defdelegate get_stockable(identifiers, opts), to: @service
  defdelegate update_stockable(id_or_stockable, fields, opts), to: @service
  defdelegate delete_stockable(id_or_stockable, opts), to: @service
  defdelegate delete_all_stockable(opts), to: @service

  defdelegate list_unlockable(params, opts), to: @service
  defdelegate count_unlockable(params \\ %{}, opts), to: @service
  defdelegate create_unlockable(fields, opts), to: @service
  defdelegate get_unlockable(identifiers, opts), to: @service
  defdelegate update_unlockable(id_or_unlockable, fields, opts), to: @service
  defdelegate delete_unlockable(id_or_unlockable, opts), to: @service
  defdelegate delete_all_unlockable(opts), to: @service

  defdelegate list_depositable(params, opts), to: @service
  defdelegate count_depositable(params \\ %{}, opts), to: @service
  defdelegate create_depositable(fields, opts), to: @service
  defdelegate get_depositable(identifiers, opts), to: @service
  defdelegate update_depositable(id_or_depositable, fields, opts), to: @service
  defdelegate delete_depositable(id_or_depositable, opts), to: @service
  defdelegate delete_all_depositable(opts), to: @service
end