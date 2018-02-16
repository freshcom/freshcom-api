defmodule BlueJet.Fulfillment.FulfillmentPackage do
  @moduledoc """
  """
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias BlueJet.Fulfillment.FulfillmentPackage.Proxy
  alias BlueJet.Fulfillment.FulfillmentItem

  schema "fulfillment_packages" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :system_label, :string

    # pending, in_progress, partially_fulfilled, fulfilled, partially_returned, returned, discarded
    field :status, :string, default: "pending"
    field :code, :string
    field :name, :string
    field :label, :string

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :order_id, Ecto.UUID
    field :order, :map, virtual: true

    field :customer_id, Ecto.UUID
    field :customer, :map, virtual: true

    field :file_collections, {:array, :map}, default: [], virtual: true

    timestamps()

    has_many :items, FulfillmentItem, foreign_key: :package_id
  end

  @type t :: Ecto.Schema.t

  @system_fields [
    :id,
    :account_id,
    :system_label,
    :status,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  def translatable_fields do
    __MODULE__.__trans__(:fields)
  end

  def validate(changeset = %{ action: :insert }) do
    changeset
    |> validate_required([:order_id])
    |> validate_inclusion(:status, ["pending", "in_progress", "fulfilled"])
  end

  def validate(changeset = %{ action: :update }) do
    changeset
    |> validate_inclusion(:status, ["pending", "in_progress", "fulfilled"])
  end

  defp castable_fields(:insert) do
    writable_fields()
  end

  defp castable_fields(:update) do
    writable_fields -- [:order_id, :customer_id]
  end

  #
  # MARK: Reader
  #
  def get_status(fulfillment_package) do
    fulfillment_package = Repo.preload(fulfillment_package, :items)
    items = fulfillment_package.items

    pending_count = Enum.reduce(items, 0, fn(item, acc) ->
      if item.status in ["pending", "in_progress"], do: acc + 1, else: acc
    end)

    fulfilled_count = Enum.reduce(items, 0, fn(item, acc) ->
      if item.status == "fulfilled", do: acc + 1, else: acc
    end)

    partially_returned_count = Enum.reduce(items, 0, fn(item, acc) ->
      if item.status == "partially_returned", do: acc + 1, else: acc
    end)

    returned_count = Enum.reduce(items, 0, fn(item, acc) ->
      if item.status == "returned", do: acc + 1, else: acc
    end)

    discarded_count = Enum.reduce(items, 0, fn(item, acc) ->
      if item.status == "discarded", do: acc + 1, else: acc
    end)

    cond do
      fulfilled_count == 0 && partially_returned_count == 0 && returned_count == 0 ->
        if fulfillment_package.status in ["pending", "in_progress"], do: fulfillment_package.status, else: "pending"

      discarded_count > 0 && pending_count == 0 && fulfilled_count == 0 && partially_returned_count == 0 && returned_count == 0 ->
        "discarded"

      returned_count > 0 && pending_count == 0 && fulfilled_count == 0 && partially_returned_count == 0 ->
        "returned"

      pending_count > 0 ->
        "paritally_fulfilled"

      partially_returned_count > 0 || returned_count > 0 ->
        "partially_returned"

      fulfilled_count > 0 ->
        "fulfilled"
    end
  end

  #
  # MARK: Changeset
  #
  def changeset(fulfillment_package, :insert, params) do
    fulfillment_package
    |> cast(params, castable_fields(:insert))
    |> Map.put(:action, :insert)
    |> validate()
  end

  def changeset(fulfillment_package, :update, params, locale \\ nil, default_locale \\ nil) do
    fulfillment_package = Proxy.put_account(fulfillment_package)
    default_locale = default_locale || fulfillment_package.account.default_locale
    locale = locale || default_locale

    fulfillment_package
    |> cast(params, castable_fields(:update))
    |> Map.put(:action, :update)
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end
end
