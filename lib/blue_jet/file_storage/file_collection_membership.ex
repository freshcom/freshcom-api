defmodule BlueJet.FileStorage.FileCollectionMembership do
  use BlueJet, :data

  alias BlueJet.FileStorage.FileCollection
  alias BlueJet.FileStorage.File

  schema "file_collection_memberships" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :sort_index, :integer, default: 100

    timestamps()

    belongs_to :collection, FileCollection
    belongs_to :file, File
  end

  @type t :: Ecto.Schema.t

  @system_fields [
    :id,
    :account_id,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:collection_id, :file_id]
  end

  defp validate_collection_id(changeset = %{ valid?: true, changes: %{ collection_id: collection_id } }) do
    account_id = get_field(changeset, :account_id)
    collection = Repo.get(FileCollection, collection_id)

    if collection && collection.account_id == account_id do
      changeset
    else
      add_error(changeset, :collection, "is invalid", [validation: :must_exist])
    end
  end

  defp validate_collection_id(changeset), do: changeset

  defp validate_file_id(changeset = %{ valid?: true, changes: %{ file_id: file_id } }) do
    account_id = get_field(changeset, :account_id)
    file = Repo.get(File, file_id)

    if file && file.account_id == account_id do
      changeset
    else
      add_error(changeset, :file, "is invalid", [validation: :must_exist])
    end
  end

  defp validate_file_id(changeset), do: changeset

  def validate(changeset) do
    changeset
    |> validate_required([:collection_id, :file_id])
    |> validate_collection_id()
    |> validate_file_id()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(fcm, :delete) do
    change(fcm)
    |> Map.put(:action, :delete)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
  end
end
