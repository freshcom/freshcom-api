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

  alias BlueJet.Fulfillment.CrmService
  alias BlueJet.Fulfillment.{FulfillmentPackage, FulfillmentItem, ReturnPackage, Unlock}
  alias BlueJet.Fulfillment.ReturnItem.Proxy

  schema "return_items" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    # pending, in_progress, returned
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

    field :order_line_item_id, Ecto.UUID
    field :order_line_item, :map, virtual: true

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

  defp validate_status(changeset = %{ data: %{ status: "pending" } }) do
    changeset
    |> validate_inclusion(:status, ["pending", "in_progress", "returned"])
  end

  defp validate_status(changeset = %{ data: %{ status: "in_progress" } }) do
    changeset
    |> validate_inclusion(:status, ["pending", "in_progress", "returned"])
  end

  defp validate_status(changeset = %{
    data: %{ status: "returned" },
    changes: %{ status: _ }
  }) do
    add_error(changeset, :status, "is not changeable", validation: :unchangeable)
  end

  defp validate_status(changeset), do: changeset

  def validate(changeset = %{ action: :insert }) do
    changeset
    |> validate_required([:fulfillment_item_id, :status])
    |> validate_inclusion(:status, ["pending", "in_progress", "returned"])
  end

  def validate(changeset = %{ action: :update }) do
    changeset
    |> validate_status()
  end

  def validate(changeset = %{ action: :delete }) do
    changeset
    |> validate_inclusion(:status, ["pending", "in_progress"])
  end

  #
  # MARK: Changeset
  #
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
    changeset
    |> put_change(:target_type, fulfillment_item.target_type)
    |> put_change(:target_id, fulfillment_item.target_id)
  end

  defp put_target(changeset), do: changeset

  defp put_order_id(changeset = %{ action: :insert, data: %{ fulfillment_item: fulfillment_item }}) do
    put_change(changeset, :order_id, fulfillment_item.order_id)
  end

  defp put_order_id(changeset), do: changeset

  defp put_order_line_item_id(changeset = %{ action: :insert, data: %{ fulfillment_item: fulfillment_item }}) do
    put_change(changeset, :order_line_item_id, fulfillment_item.order_line_item_id)
  end

  defp put_order_line_item_id(changeset), do: changeset

  defp put_name(changeset = %{ action: :insert, data: %{ fulfillment_item: fulfillment_item }}) do
    put_change(changeset, :name, fulfillment_item.name)
  end

  defp put_name(changeset), do: changeset

  defp put_translations(changeset = %{ action: :insert, data: %{ fulfillment_item: fulfillment_item }}) do
    translations = Translation.merge_translations(%{}, fulfillment_item.translations, ["name"])
    put_change(changeset, :translations, translations)
  end

  defp put_translations(changeset), do: changeset

  def changeset(return_item, :insert, params) do
    return_item
    |> cast(params, writable_fields())
    |> Map.put(:action, :insert)
    |> put_fulfillment_item()
    |> put_order_id()
    |> put_order_line_item_id()
    |> put_target()
    |> put_name()
    |> put_translations()
    |> validate()
  end

  def changeset(return_item, :update, params, locale \\ nil, default_locale \\ nil) do
    return_item = Proxy.put_account(return_item)
    default_locale = default_locale || return_item.account.default_locale
    locale = locale || default_locale

    return_item
    |> cast(params, writable_fields())
    |> Map.put(:action, :update)
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  #
  # MARK: Preprocess
  #
  defp get_or_create_auto_return_package(changeset) do
    account_id = get_field(changeset, :account_id)
    order_id = get_field(changeset, :order_id)
    case Repo.get_by(ReturnPackage, account_id: account_id, order_id: order_id, system_label: "auto") do
      nil ->
        Repo.insert!(%ReturnPackage{ account_id: account_id, order_id: order_id, system_label: "auto", status: "returned" })

      other -> other
    end
  end

  defp return_unlockable(unlock_id) do
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
      changes: %{ status: "returned" }
    },
    %{
      source_type: "Unlock",
      source_id: unlock_id
    }
  ) do
    {:ok, _} = return_unlockable(unlock_id)
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

  def preprocess(changeset = %{ changes: %{ package_id: _ } }, _), do: changeset

  def preprocess(changeset, _) do
    package = get_or_create_auto_return_package(changeset)
    changeset =
      changeset
      |> put_change(:package_id, package.id)

    {:ok, changeset}
  end

  def preprocess(changeset = %{
      action: :insert,
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

  #
  # MARK: Process
  #
  def process(return_item, %{
    changes: %{ status: "returned" }
  }) do
    return_item = Repo.preload(return_item, [:package, fulfillment_item: :package])
    return_package = return_item.package
    fulfillment_item = return_item.fulfillment_item
    fulfillment_package = fulfillment_item.package

    # Return Package
    change(return_item.package, %{ status: ReturnPackage.get_status(return_package) })
    |> Repo.update!()

    # Fulfillment Item
    new_status = FulfillmentItem.get_status(fulfillment_item)
    new_returned_quantity = fulfillment_item.returned_quantity + return_item.quantity
    new_gross_quantity = fulfillment_item.quantity - new_returned_quantity

    change(fulfillment_item, %{
      status: new_status,
      returned_quantity: new_returned_quantity,
      gross_quantity: new_gross_quantity
    })
    |> Repo.update!()

    # Fulfillment Package
    change(fulfillment_package, %{ status: FulfillmentPackage.get_status(fulfillment_package) })
    |> Repo.update!()

    {:ok, return_item}
  end
end
