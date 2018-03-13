defmodule BlueJet.Storefront.Service do
  @service Application.get_env(:blue_jet, :storefront)[:service]

  @callback list_order(map, map) :: [Order.t]
  @callback count_order(map, map) :: integer
  @callback create_order(map, map) :: {:ok, Order.t} | {:error, any}
  @callback get_order(map, map) :: Order.t | nil
  @callback update_order(Order.t | String.t, map, map) :: {:ok, Order.t} | {:error, any}
  @callback delete_order(Order.t | String.t, map) :: {:ok, Order.t} | {:error, any}
  @callback delete_all_order(map) :: :ok

  @callback create_order_line_item(map, map) :: {:ok, OrderLineItem.t} | {:error, any}
  @callback update_order_line_item(OrderLineItem.t | String.t, map, map) :: {:ok, OrderLineItem.t} | {:error, any}
  @callback delete_order_line_item(OrderLineItem.t | String.t, map) :: {:ok, OrderLineItem.t} | {:error, any}

  defdelegate list_order(params, opts), to: @service
  defdelegate count_order(params \\ %{}, opts), to: @service
  defdelegate create_order(fields, opts), to: @service
  defdelegate get_order(identifiers, opts), to: @service
  defdelegate update_order(id_or_order, fields, opts), to: @service
  defdelegate delete_order(id_or_order, opts), to: @service
  defdelegate delete_all_order(opts), to: @service

  defdelegate create_order_line_item(fields, opts), to: @service
  defdelegate update_order_line_item(id_or_oli, fields, opts), to: @service
  defdelegate delete_order_line_item(id_or_oli, opts), to: @service
end