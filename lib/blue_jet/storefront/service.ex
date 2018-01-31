defmodule BlueJet.Storefront.Service do
  use BlueJet, :service

  alias BlueJet.Storefront.{IdentityService, BalanceService}
  alias BlueJet.Storefront.Order

  alias Ecto.Multi
  alias Ecto.Changeset

  @callback list_order(map, map) :: list
  @callback count_order(map, map) :: integer

  defp get_account(opts) do
    opts[:account] || IdentityService.get_account(opts)
  end

  def list_order(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    Order.Query.default()
    |> Order.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Order.Query.filter_by(filter)
    |> Order.Query.for_account(account.id)
    |> Order.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_order(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    Order.Query.default()
    |> Order.Query.search(fields[:search], opts[:locale], opts[:default_locale])
    |> Order.Query.filter_by(filter)
    |> Order.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_order(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %Order{ account_id: account.id, account: account }
      |> Order.changeset(:insert, fields)

    with {:ok, order} <- Repo.insert(changeset) do
      order = preload(order, preloads[:path], preloads[:opts])

      {:ok, order}
    else
      other -> other
    end
  end

  def get_order(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    Order.Query.default()
    |> Order.Query.for_account(account.id)
    |> Repo.get_by(fields)
    |> preload(preloads[:path], preloads[:opts])
  end

  def update_order(nil, _, _), do: {:error, :not_found}

  def update_order(order = %Order{}, fields, opts) do
    account = get_account(opts)
    changeset = Order.changeset(order, :update, fields, opts[:locale], account.default_locale)

    statements =
      Multi.new()
      |> Multi.update(:order, changeset)
      |> Multi.run(:processed_order, fn(%{ order: order}) ->
          Order.process(order, changeset)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_order: order }} ->
        {:ok, order}

      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def update_order(id, fields, opts) do
    account = get_account(opts)

    order = Repo.get_by(Order, id: id, account_id: account.id)
    update_order(order, fields, opts)
  end

  def delete_order(nil, _), do: nil

  def delete_order(order = %Order{}, opts) do
    changeset = Order.changeset(order, :delete)

    with {:ok, _} <- Repo.delete(changeset) do
      %{ filter: %{ target_type: "Order", target_id: order.id } }
    else
      other -> other
    end
  end

  def delete_order(id, opts) do
    account = get_account(opts)

    order = Repo.get_by(Order, id: id, account_id: account.id)
    delete_order(order, opts)
  end
end