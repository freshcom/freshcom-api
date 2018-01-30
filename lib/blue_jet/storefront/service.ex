defmodule BlueJet.Storefront.Service do
  use BlueJet, :service

  alias BlueJet.Repo
  alias BlueJet.Storefront.IdentityService
  alias BlueJet.Storefront.Order

  @callback list_order(map, map) :: list
  @callback count_order(map, map) :: integer

  defp get_account(opts) do
    opts[:account] || IdentityService.get_account(opts)
  end

  def list_order(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(fields)
    preloads = get_preloads(fields, account)
    filter = get_filter(fields)

    preload_query = Order.Query.preloads(preloads[:path], preloads[:filter])
    Order.Query.default()
    |> Order.Query.not_cart()
    |> Order.Query.search(fields[:search], opts[:locale], opts[:default_locale])
    |> Order.Query.filter_by(filter)
    |> Order.Query.for_account(account.id)
    |> Order.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> Repo.preload(preload_query)
    |> Order.Proxy.put(preloads[:path], preloads[:opts])
  end

  def count_order(fields, opts) do
    # "membership.product.prices"
    # [membership: {filters, product: {filters, :prices}}]
  end
end