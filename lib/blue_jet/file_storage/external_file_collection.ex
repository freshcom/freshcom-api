defmodule BlueJet.FileStorage.ExternalFileCollection do
  use BlueJet, :data

  use Trans, translates: [:name, :custom_data], container: :translations

  alias BlueJet.Translation
  alias BlueJet.FileStorage.ExternalFile
  alias BlueJet.FileStorage.ExternalFileCollection
  alias BlueJet.FileStorage.ExternalFileCollectionMembership

  schema "external_file_collections" do
    field :account_id, Ecto.UUID

    field :name, :string
    field :label, :string

    field :owner_id, Ecto.UUID
    field :owner_type, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, defualt: %{}

    timestamps()

    has_many :file_memberships, ExternalFileCollectionMembership, foreign_key: :collection_id
    has_many :files, through: [:file_memberships, :file]
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    ExternalFileCollection.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    ExternalFileCollection.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required([:account_id, :label])
    |> foreign_key_constraint(:account_id)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> Translation.put_change(translatable_fields(), locale)
  end

  def file_count(%ExternalFileCollection{ id: efc_id }) do
    from(efcm in ExternalFileCollectionMembership,
      select: count(efcm.id),
      where: efcm.collection_id == ^efc_id)
    |> Repo.one()
  end

  defmodule Query do
    use BlueJet, :query

    def for_owner_type(owner_type) do
      from(efc in ExternalFileCollection, where: efc.owner_type == ^owner_type, order_by: [desc: efc.updated_at])
    end

    def for_account(query, account_id) do
      from(efc in query, where: efc.account_id == ^account_id)
    end

    def preloads(:files) do
      [files: ExternalFile.Query.default()]
    end

    def default() do
      from(efc in ExternalFileCollection, order_by: [desc: efc.updated_at])
    end
  end
end
