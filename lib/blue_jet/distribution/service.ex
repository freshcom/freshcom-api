defmodule BlueJet.Distribution.Service do
  use BlueJet, :service
  use BlueJet.EventEmitter, namespace: :distribution

  alias Ecto.Multi
  alias BlueJet.Distribution.IdentityService
  alias BlueJet.Distribution.{Fulfillment, FulfillmentLineItem}

  defp get_account(opts) do
    opts[:account] || IdentityService.get_account(opts)
  end

  def create_fulfillment(fields, opts) do
    account = get_account(opts)

    %Fulfillment{ account_id: account.id, account: account }
    |> Fulfillment.changeset(:insert, fields)
    |> Repo.insert()
  end

  def list_fulfillment(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    Fulfillment.Query.default()
    |> Fulfillment.Query.filter_by(filter)
    |> Fulfillment.Query.for_account(account.id)
    |> Fulfillment.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_fulfillment(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    Fulfillment.Query.default()
    |> Fulfillment.Query.filter_by(filter)
    |> Fulfillment.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_fulfillment_line_item(fields, opts) do
    account = get_account(opts)

    changeset =
      %FulfillmentLineItem{ account_id: account.id, account: account }
      |> FulfillmentLineItem.changeset(:insert, fields)

    statements =
      Multi.new()
      |> Multi.insert(:fulfillment_line_item, changeset)
      |> Multi.run(:after_create, fn(%{ fulfillment_line_item: fli }) ->
          emit_event("distribution.fulfillment_line_item.after_create", %{ fulfillment_line_item: fli })
         end)

    case Repo.transaction(statements) do
      {:ok, %{ fulfillment_line_item: fli }} -> {:ok, fli}

      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def list_fulfillment_line_item(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    FulfillmentLineItem.Query.default()
    |> FulfillmentLineItem.Query.filter_by(filter)
    |> FulfillmentLineItem.Query.for_account(account.id)
    |> FulfillmentLineItem.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_fulfillment_line_item(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    FulfillmentLineItem.Query.default()
    |> FulfillmentLineItem.Query.filter_by(filter)
    |> FulfillmentLineItem.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end
end