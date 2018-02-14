defmodule BlueJet.Fulfillment.ReturnItem do
  @moduledoc """
  """
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :print_name,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias BlueJet.Fulfillment.{GoodsService, CrmService}
  alias BlueJet.Fulfillment.{FulfillmentItem, ReturnPackage, Unlock}
  alias BlueJet.Fulfillment.ReturnItem.Proxy

  schema "return_items" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string, default: "pending"
    field :code, :string
    field :name, :string
    field :label, :string

    field :quantity, :integer
    field :print_name, :string

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :order_id, Ecto.UUID
    field :order, :map, virtual: true

    field :target_id, Ecto.UUID
    field :target_type, :string
    field :target, :map, virtual: true

    field :source_id, Ecto.UUID
    field :source_type, :string
    field :source, :map, virtual: true

    field :file_collections, {:array, :map}, default: [], virtual: true

    timestamps()

    belongs_to :package, ReturnPackage
    belongs_to :fulfillment_item, FulfillmentItem
  end

  @system_fields [
    :id,
    :order_id,
    :target_id,
    :target_type,
    :source_id,
    :source_type,
    :account_id,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  def translatable_fields do
    __MODULE__.__trans__(:fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required([:fulfillment_item_id])
  end

  defp get_fulfillment_item(changeset) do
    fulfillment_item_id = get_field(changeset, :fulfillment_item_id)
    get_field(changeset, :fulfillment_item) || Repo.get(FulfillmentItem, fulfillment_item_id)
  end

  defp put_fulfillment_item(changeset) do
    fulfillment_item = get_fulfillment_item(changeset)
    data = %{ changeset.data | fulfillment_item: fulfillment_item }
    %{ changeset | data: data }
  end

  defp put_target(changeset = %{ action: :insert, data: %{ fulfillment_item: fulfillment_item } }) do
    changeset =
      changeset
      |> put_change(:target_type, fulfillment_item.target_type)
      |> put_change(:target_id, fulfillment_item.target_id)
  end

  defp put_target(changeset), do: changeset

  defp put_order_id(changeset = %{ action: :insert, data: %{ fulfillment_item: fulfillment_item }}) do
    put_change(changeset, :order_id, fulfillment_item.order_id)
  end

  defp put_order_id(changeset), do: changeset

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(fulfillment_item, :insert, params) do
    fulfillment_item
    |> cast(params, writable_fields())
    |> Map.put(:action, :insert)
    |> put_fulfillment_item()
    |> put_order_id()
    |> put_target()
    |> validate()
  end

  def changeset(fulfillment_item, :update, params, locale \\ nil, default_locale \\ nil) do
    fulfillment_item = Proxy.put_account(fulfillment_item)
    default_locale = default_locale || fulfillment_item.account.default_locale
    locale = locale || default_locale

    fulfillment_item
    |> cast(params, writable_fields())
    |> Map.put(:action, :update)
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  defp get_or_create_auto_return_package(changeset) do
    account_id = get_field(changeset, :account_id)
    order_id = get_field(changeset, :order_id)
    case Repo.get_by(ReturnPackage, account_id: account_id, order_id: order_id, system_label: "auto") do
      nil ->
        Repo.insert!(%ReturnPackage{ account_id: account_id, order_id: order_id, system_label: "auto" })

      other -> other
    end
  end

  defp return_unlockable(unlock_id, opts) do
    unlock =
      Repo.get!(Unlock, unlock_id)
      |> Repo.delete!()

    {:ok, unlock}
  end

  defp return_depositable(pt_id, fulfilled_quantity, return_quantity, opts) do
    point_transaction = CrmService.get_point_transaction(%{ id: pt_id }, opts)
    return_amount = - div(point_transaction.amount, fulfilled_quantity) * return_quantity

    CrmService.create_point_transaction(%{
      point_account_id: point_transaction.point_account_id,
      status: "committed",
      amount: return_amount,
      reason_label: "return_depositable"
    }, opts)
  end

  defp return_point_transaction(pt_id, opts) do
    point_transaction = CrmService.get_point_transaction(%{ id: pt_id }, opts)
    CrmService.create_point_transaction(%{
      point_account_id: point_transaction.point_account_id,
      status: "committed",
      amount: -point_transaction.amount,
      reason_label: "return"
    }, opts)
  end

  def preprocess(changeset = %{
      data: %{ account: account },
      changes: %{ status: "returned" }
    },
    %{
      source_type: "Unlock",
      source_id: unlock_id
    }
  ) do
    opts = %{ account: account }
    {:ok, unlock} = return_unlockable(unlock_id, opts)
    package = get_or_create_auto_return_package(changeset)
    changeset = put_change(changeset, :package_id, package.id)

    {:ok, changeset}
  end

  def preprocess(changeset = %{
      data: %{ account: account },
      changes: %{ status: "returned", quantity: return_quantity }
    },
    %{
      target_type: "Depositable",
      target_id: depositable_id,
      source_type: "PointTransaction",
      source_id: point_transaction_id,
      quantity: fulfilled_quantity
    }
  ) do
    opts = %{ account: account }

    case return_depositable(point_transaction_id, fulfilled_quantity, return_quantity, opts) do
      {:ok, nil} ->
        {:ok, changeset}

      {:ok, point_transaction} ->
        package = get_or_create_auto_return_package(changeset)
        changeset =
          changeset
          |> put_change(:package_id, package.id)
          |> put_change(:source_type, "PointTransaction")
          |> put_change(:source_id, point_transaction.id)
        {:ok, changeset}

      other -> other
    end
  end

  def preprocess(changeset = %{
      data: %{ account: account },
      changes: %{ status: "returned" }
    },
    %{
      target_type: "PointTransaction",
      target_id: point_transaction_id
    }
  ) do
    opts = %{ account: account }

    case return_point_transaction(point_transaction_id, opts) do
      {:ok, point_transaction} ->
        package = get_or_create_auto_return_package(changeset)
        changeset =
          changeset
          |> put_change(:package_id, package.id)
          |> put_change(:source_type, "PointTransaction")
          |> put_change(:source_id, point_transaction.id)
        {:ok, changeset}

      other -> other
    end
  end

  def preprocess(changeset = %{
      action: :insert,
      data: data,
      changes: %{ status: "returned" }
    }
  ) do
    fulfillment_item = get_fulfillment_item(changeset)
    preprocess(changeset, fulfillment_item)
  end

  def preprocess(changeset = %{
      action: :update,
      data: data,
      changes: %{ status: "returned" }
    }
  ) do
    data = Repo.preload(data, :fulfillment_item)
    preprocess(changeset, data.fulfillment_item)
  end

  def process(return_item, %{
    changes: %{ status: "returned" }
  }) do
    return_item = Repo.preload(return_item, :fulfillment_item)
    fulfillment_item = return_item.fulfillment_item

    new_status = FulfillmentItem.get_status(fulfillment_item)
    new_returned_quantity = fulfillment_item.returned_quantity + return_item.quantity
    new_gross_quantity = fulfillment_item.quantity - new_returned_quantity

    change(fulfillment_item, %{
      status: new_status,
      returned_quantity: new_returned_quantity,
      gross_quantity: new_gross_quantity
    })
    |> Repo.update!()

    {:ok, return_item}
  end
end
