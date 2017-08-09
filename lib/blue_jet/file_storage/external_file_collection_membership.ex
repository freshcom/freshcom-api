defmodule BlueJet.FileStorage.ExternalFileCollectionMembership do
  use BlueJet, :data

  alias BlueJet.FileStorage.ExternalFileCollectionMembership
  alias BlueJet.FileStorage.ExternalFileCollection
  alias BlueJet.FileStorage.ExternalFile
  alias BlueJet.Identity.Account

  schema "external_file_collection_memberships" do
    field :sort_index, :integer, default: 100

    timestamps()

    belongs_to :account, Account
    belongs_to :collection, ExternalFileCollection
    belongs_to :file, ExternalFile
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    ExternalFileCollectionMembership.__schema__(:fields) -- system_fields()
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id, :collection_id, :file_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required([:account_id, :collection_id, :file_id])
    |> foreign_key_constraint(:account_id)
    |> validate_assoc_account_scope([:collection, :file])
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
  end
end
