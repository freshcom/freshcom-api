defmodule BlueJet.FileStorage.FileCollectionMembership do
  use BlueJet, :data

  alias BlueJet.FileStorage.{File, FileCollection}

  schema "file_collection_memberships" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :sort_index, :integer, default: 1000

    timestamps()

    belongs_to :collection, FileCollection
    belongs_to :file, File
  end

  @type t :: Ecto.Schema.t()

  @system_fields [
    :id,
    :account_id,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  @spec changeset(__MODULE__.t(), atom) :: Changeset.t()
  def changeset(fcm, :delete) do
    change(fcm)
    |> Map.put(:action, :delete)
  end

  @spec changeset(__MODULE__.t(), atom, map) :: Changeset.t()
  def changeset(fcm, :insert, params) do
    fcm
    |> cast(params, castable_fields(:insert))
    |> Map.put(:action, :insert)
    |> validate()
  end

  def changeset(fcm, :update, params) do
    fcm
    |> cast(params, castable_fields(:update))
    |> Map.put(:action, :update)
    |> validate()
  end

  defp castable_fields(:insert) do
    writable_fields()
  end

  defp castable_fields(:update) do
    writable_fields() -- [:collection_id, :file_id]
  end

  defp validate(changeset) do
    changeset
    |> validate_required([:collection_id, :file_id])
    |> validate_collection_id()
    |> validate_file_id()
  end

  defp validate_collection_id(
         changeset = %{valid?: true, changes: %{collection_id: collection_id}}
       ) do
    account_id = get_field(changeset, :account_id)
    collection = Repo.get(FileCollection, collection_id)

    if collection && collection.account_id == account_id do
      changeset
    else
      add_error(changeset, :collection, "is invalid", code: :invalid)
    end
  end

  defp validate_collection_id(changeset), do: changeset

  defp validate_file_id(changeset = %{valid?: true, changes: %{file_id: file_id}}) do
    account_id = get_field(changeset, :account_id)
    file = Repo.get(File, file_id)

    if file && file.account_id == account_id do
      changeset
    else
      add_error(changeset, :file, "is invalid", code: :invalid)
    end
  end

  defp validate_file_id(changeset), do: changeset
end
