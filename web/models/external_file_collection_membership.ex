defmodule BlueJet.ExternalFileCollectionMembership do
  use BlueJet.Web, :model

  schema "external_file_collection_memberships" do
    field :sort_index, :integer, default: 100

    timestamps()

    belongs_to :account, BlueJet.Account
    belongs_to :collection, BlueJet.ExternalFileCollection
    belongs_to :file, BlueJet.ExternalFile
  end

  def fields do
    BlueJet.ExternalFileCollectionMembership.__schema__(:fields)
    -- [:id, :inserted_at, :updated_at]
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    fields() -- [:account_id, :collection_id, :file_id]
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
