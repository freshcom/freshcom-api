defmodule BlueJet.Fulfillment.Unlock do
  use BlueJet, :data

  schema "unlocks" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :sort_index, :integer, default: 1000
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

  @system_fields [
    :id,
    :account_id,
    :inserted_at,
    :updated_at
  ]

  @type t :: Ecto.Schema.t()

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  def translatable_fields do
    [:custom_data]
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  @spec changeset(__MODULE__.t(), atom, map) :: Changeset.t()
  def changeset(unlock, :insert, params) do
    unlock
    |> cast(params, castable_fields(:insert))
    |> Map.put(:action, :insert)
    |> validate()
  end

  @spec changeset(__MODULE__.t(), atom) :: Changeset.t()
  def changeset(unlock, :delete) do
    change(unlock)
    |> Map.put(:action, :delete)
  end

  defp castable_fields(:insert) do
    writable_fields()
  end

  defp castable_fields(:update) do
    writable_fields() -- [:unlockable_id, :customer_id]
  end

  defp required_fields do
    [:unlockable_id, :customer_id]
  end

  @spec validate(Changeset.t()) :: Changeset.t()
  def validate(changeset) do
    changeset
    |> validate_required(required_fields())
    |> validate_unlockable_id()
  end

  defp validate_unlockable_id(changeset = %{valid?: true}) do
    customer_id = get_field(changeset, :customer_id)
    unlockable_id = get_field(changeset, :unlockable_id)

    if Repo.get_by(__MODULE__, customer_id: customer_id, unlockable_id: unlockable_id) do
      add_error(
        changeset,
        :unlockable_id,
        "Unlockable is already unlocked",
        code: :already_unlocked,
        full_error_message: true
      )
    else
      changeset
    end
  end

  defp validate_unlockable_id(changeset), do: changeset

  def source(struct) do
    struct.stockable || struct.unlockable
  end
end
