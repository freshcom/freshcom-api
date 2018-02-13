defmodule BlueJet.Distribution.Unlock do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  schema "unlocks" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :sort_index, :integer, default: 0
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :source_id, Ecto.UUID
    field :source_type, :string
    field :source, :map, virtual: true

    field :unlockable_id, Ecto.UUID
    field :unlockable, :map, virtual: true

    field :customer_id, Ecto.UUID
    field :customer, :map, virtual: true

    timestamps()
  end

  def source(struct) do
    struct.stockable || struct.unlockable
  end

  @system_fields [
    :id,
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

  def castable_fields(:insert) do
    writable_fields()
  end

  def castable_fields(:update) do
    writable_fields() -- [:unlockable_id, :customer_id]
  end

  def required_fields do
    [:unlockable_id, :customer_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields())
    |> unique_constraint(:unlockable_id, name: :unlocks_customer_id_unlockable_id_index)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(unlock, :insert, params) do
    unlock
    |> cast(params, castable_fields(:insert))
    |> Map.put(:action, :insert)
    |> validate()
  end

  def changeset(unlock, :delete) do
    change(unlock)
    |> Map.put(:action, :delete)
  end
end
