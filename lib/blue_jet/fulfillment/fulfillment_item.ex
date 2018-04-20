defmodule BlueJet.Fulfillment.FulfillmentItem do
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
  alias BlueJet.Fulfillment.{FulfillmentPackage, ReturnItem, Unlock}
  alias __MODULE__.Proxy

  schema "fulfillment_items" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    # pending, in_progress, fulfilled, partially_returned, returned, discarded
    field :status, :string, default: "pending"
    field :code, :string
    field :name, :string
    field :label, :string

    field :quantity, :integer
    field :returned_quantity, :integer, default: 0, null: false
    field :gross_quantity, :integer, default: 0, null: false
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

    belongs_to :package, FulfillmentPackage
  end

  @system_fields [
    :id,
    :account_id,
    :order_id,
    :returned_quantity,
    :gross_quantity,
    :order_id,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  def translatable_fields do
    __MODULE__.__trans__(:fields)
  end

  #
  # MARK: Private Helper
  #
  defp get_package(changeset) do
    account_id = get_field(changeset, :account_id)
    package_id = get_field(changeset, :package_id)

    package = if package_id do
      get_field(changeset, :package) || Repo.get_by(FulfillmentPackage, account_id: account_id, id: package_id)
    else
      nil
    end

    package
  end

  #
  # MARK: Validation
  #
  defp validate_package_id(changeset = %{
    action: :insert,
    valid?: true,
    changes: %{ package_id: _ }
  }) do
    package = get_package(changeset)

    if package do
      changeset
    else
      add_error(changeset, :package_id, "is invalid", validation: :must_exist)
    end
  end

  defp validate_package_id(changeset), do: changeset

  defp validate_status(changeset = %{ data: %{ status: "pending" } }) do
    changeset
    |> validate_inclusion(:status, ["pending", "in_progress", "fulfilled", "discarded"])
  end

  defp validate_status(changeset = %{ data: %{ status: "in_progress" } }) do
    changeset
    |> validate_inclusion(:status, ["pending", "in_progress", "fulfilled", "discarded"])
  end

  defp validate_status(changeset = %{ data: %{ status: "fulfilled" } }) do
    changeset
    |> validate_inclusion(:status, ["fulfilled", "discarded"])
  end

  defp validate_status(changeset = %{
    changes: %{ status: _ }
  }) do
    add_error(changeset, :status, "is not changeable", validation: :unchangeable)
  end

  defp validate_status(changeset), do: changeset

  def validate(changeset = %{ action: :insert }) do
    changeset
    |> validate_required([:status, :quantity, :order_line_item_id, :package_id])
    |> validate_inclusion(:status, ["pending", "fulfilled"])
    |> validate_package_id()
  end

  def validate(changeset = %{ action: :update }) do
    changeset
    |> validate_status()
  end

  def validate(changeset = %{ action: :delete }) do
    changeset
    |> validate_inclusion(:status, ["pending", "in_progress", "discarded"])
  end

  #
  # MARK: Changeset
  #
  defp put_package(changeset) do
    data = %{ changeset.data | package: get_package(changeset) }
    %{ changeset | data: data }
  end

  defp put_order_id(changeset = %{ action: :insert }) do
    package = get_package(changeset)

    if package do
      put_change(changeset, :order_id, package.order_id)
    else
      changeset
    end
  end

  defp put_order_id(changeset), do: changeset

  defp put_gross_quantity(changeset = %{ action: :insert }) do
    put_change(changeset, :gross_quantity, get_field(changeset, :quantity))
  end

  defp put_gross_quantity(changeset), do: changeset

  def changeset(fulfillment_item, :insert, params) do
    fulfillment_item
    |> cast(params, writable_fields())
    |> Map.put(:action, :insert)
    |> put_package()
    |> put_order_id()
    |> put_gross_quantity()
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

  def changeset(fulfillment_item, :delete) do
    change(fulfillment_item)
    |> Map.put(:action, :delete)
    |> validate()
  end

  #
  # MARK: Reader
  #
  def get_returned_quantity(fulfillment_item) do
    returned_quantity =
      ReturnItem.Query.default()
      |> ReturnItem.Query.filter_by(%{ fulfillment_item_id: fulfillment_item.id, status: "returned" })
      |> Repo.aggregate(:sum, :quantity)

    returned_quantity || 0
  end

  def get_status(fulfillment_item) do
    returned_quantity = get_returned_quantity(fulfillment_item)

    cond do
      returned_quantity == 0 ->
        fulfillment_item.status

      returned_quantity < fulfillment_item.quantity ->
        "partially_returned"

      returned_quantity >= fulfillment_item.quantity ->
        "returned"
    end
  end

  #
  # MARK: Preprocess
  #
  defp fulfill_unlockable(unlockable_id, customer_id, opts) do
    %Unlock{ account_id: opts[:account].id, account: opts[:account] }
    |> Unlock.changeset(:insert, %{ unlockable_id: unlockable_id, customer_id: customer_id })
    |> Repo.insert()
  end

  defp fulfill_depositable(depositable_id, quantity, customer_id, opts) do
    depositable = GoodsService.get_depositable(%{ id: depositable_id }, opts)

    if depositable.gateway == "freshcom" do
      point_account = CrmService.get_point_account(%{ customer_id: customer_id }, opts)
      CrmService.create_point_transaction(%{
        point_account_id: point_account.id,
        status: "committed",
        amount: quantity * depositable.amount,
        reason_label: "deposit_by_depositable"
      }, opts)
    else
      {:ok, nil}
    end
  end

  defp fulfill_point_transaction(pt_id, opts) do
    CrmService.update_point_transaction(pt_id, %{ status: "committed" }, opts)
  end

  defp preprocess("Unlockable", changeset = %{
    data: %{
      package: %{ customer_id: customer_id },
      account: account
    },
    changes: %{ status: "fulfilled" }
  }) do
    unlockable_id = get_field(changeset, :target_id)
    opts = %{ account: account }

    with {:ok, unlock} <- fulfill_unlockable(unlockable_id, customer_id, opts) do
      changeset =
        changeset
        |> put_change(:source_type, "Unlock")
        |> put_change(:source_id, unlock.id)

      {:ok, changeset}
    else
      {:error, %{ errors: [unlockable_id: {_, [code: :already_unlocked, full_error_message: true]}] }} ->
        changeset = add_error(changeset, :target, "The target unlockable is already unlocked", [code: :already_unlocked, full_error_message: true])
        {:error, changeset}

      other -> other
    end
  end

  defp preprocess("Depositable", changeset = %{
    data: %{
      package: %{ customer_id: customer_id },
      account: account
    },
    changes: %{ status: "fulfilled" }
  }) do
    depositable_id = get_field(changeset, :target_id)
    quantity = get_field(changeset, :quantity)

    opts = %{ account: account }
    case fulfill_depositable(depositable_id, quantity, customer_id, opts) do
      {:ok, nil} ->
        {:ok, changeset}

      {:ok, point_transaction} ->
        changeset =
          changeset
          |> put_change(:source_type, "PointTransaction")
          |> put_change(:source_id, point_transaction.id)
        {:ok, changeset}

      other -> other
    end
  end

  defp preprocess("PointTransaction", changeset = %{
    data: %{ account: account },
    changes: %{ status: "fulfilled" }
  }) do
    point_transaction_id = get_field(changeset, :target_id)
    opts = %{ account: account }

    case fulfill_point_transaction(point_transaction_id, opts) do
      {:ok, point_transaction} ->
        changeset =
          changeset
          |> put_change(:source_type, "PointTransaction")
          |> put_change(:source_id, point_transaction.id)
        {:ok, changeset}

      other -> other
    end
  end

  defp preprocess(nil, changeset), do: {:ok, changeset}

  @spec preprocess(Changeset.t) :: {:ok, Changeset.t} | {:error, Changeset.t}
  def preprocess(changeset = %{
    data: data,
    changes: %{ status: "fulfilled" }
  }) do
    data = Repo.preload(data, :package)
    changeset = %{ changeset | data: data }

    target_type = get_field(changeset, :target_type)
    preprocess(target_type, changeset)
  end

  def preprocess(changeset), do: {:ok, changeset}

  def process(fulfillment_item, %{
    changes: %{ status: _ }
  }) do
    fulfillment_item = Repo.preload(fulfillment_item, :package)
    fulfillment_package = fulfillment_item.package

    # Fulfillment Package
    change(fulfillment_package, %{ status: FulfillmentPackage.get_status(fulfillment_package) })
    |> Repo.update!()

    {:ok, fulfillment_item}
  end
end
