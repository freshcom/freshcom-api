defmodule BlueJet.Fulfillment.FulfillmentPackage do
  @moduledoc """
  """
  use BlueJet, :data

  alias __MODULE__.Proxy
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

  @type t :: Ecto.Schema.t()

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
    [
      :name,
      :caption,
      :description,
      :custom_data
    ]
  end

  @spec changeset(__MODULE__.t(), atom, map) :: Changeset.t()
  def changeset(fulfillment_package, :insert, params) do
    fulfillment_package
    |> cast(params, castable_fields(:insert))
    |> Map.put(:action, :insert)
    |> validate()
  end

  @spec changeset(__MODULE__.t(), atom, map, String.t(), String.t()) :: Changeset.t()
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

  @spec changeset(__MODULE__.t(), atom) :: Changeset.t()
  def changeset(fulfillment_package, :delete) do
    change(fulfillment_package)
    |> Map.put(:action, :delete)
    |> validate()
  end

  defp castable_fields(:insert) do
    writable_fields()
  end

  defp castable_fields(:update) do
    writable_fields() -- [:order_id, :customer_id]
  end

  @spec validate(Changeset.t()) :: Changeset.t()
  def validate(changeset = %{action: :insert}) do
    changeset
    |> validate_required([:order_id])
    |> validate_inclusion(:status, ["pending", "in_progress"])
  end

  def validate(changeset = %{action: :update}) do
    changeset
    |> validate_status()
  end

  def validate(changeset = %{action: :delete}) do
    changeset
    |> validate_inclusion(:status, ["pending", "in_progress", "discarded"])
  end

  defp validate_status(
         changeset = %{
           data: %{status: "pending"},
           changes: %{status: status}
         }
       )
       when status != "in_progress" do
    add_error(changeset, :status, "is invalid", validation: :must_be_in_progress)
  end

  defp validate_status(
         changeset = %{
           data: %{status: "in_progress"},
           changes: %{status: status}
         }
       )
       when status != "pending" do
    add_error(changeset, :status, "is invalid", validation: :must_be_pending)
  end

  defp validate_status(
         changeset = %{
           data: %{status: status},
           changes: %{status: _}
         }
       )
       when status not in ["pending", "in_progress"] do
    add_error(changeset, :status, "is not changeable", validation: :unchangeable)
  end

  defp validate_status(changeset), do: changeset

  @spec get_status(__MODULE__.t()) :: String.t()
  def get_status(fulfillment_package) do
    fulfillment_package = Repo.preload(fulfillment_package, :items)
    items = fulfillment_package.items

    fulfillable_count = length(items)

    pending_count =
      Enum.reduce(items, 0, fn item, acc ->
        if item.status in ["pending", "in_progress"], do: acc + 1, else: acc
      end)

    fulfilled_count =
      Enum.reduce(items, 0, fn item, acc ->
        if item.status == "fulfilled", do: acc + 1, else: acc
      end)

    partially_returned_count =
      Enum.reduce(items, 0, fn item, acc ->
        if item.status == "partially_returned", do: acc + 1, else: acc
      end)

    returned_count =
      Enum.reduce(items, 0, fn item, acc ->
        if item.status == "returned", do: acc + 1, else: acc
      end)

    discarded_count =
      Enum.reduce(items, 0, fn item, acc ->
        if item.status == "discarded", do: acc + 1, else: acc
      end)

    cond do
      fulfillable_count == 0 ->
        if fulfillment_package.status in ["pending", "in_progress"],
          do: fulfillment_package.status,
          else: "pending"

      pending_count > 0 && fulfilled_count == 0 && partially_returned_count == 0 &&
          returned_count == 0 ->
        if fulfillment_package.status in ["pending", "in_progress"],
          do: fulfillment_package.status,
          else: "pending"

      returned_count == 0 && partially_returned_count == 0 && fulfilled_count > 0 &&
          pending_count > 0 ->
        "partially_fulfilled"

      returned_count == 0 && partially_returned_count == 0 && pending_count == 0 &&
          fulfilled_count > 0 ->
        "fulfilled"

      partially_returned_count > 0 ->
        "partially_returned"

      returned_count > 0 && returned_count < fulfillable_count - discarded_count ->
        "partially_returned"

      returned_count > 0 && returned_count >= fulfillable_count - discarded_count ->
        "returned"

      discarded_count >= fulfilled_count ->
        "discarded"
    end
  end
end
