defmodule BlueJet.FileStorage.ExternalFileCollection do
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias BlueJet.Translation
  alias BlueJet.FileStorage.ExternalFile
  alias BlueJet.FileStorage.ExternalFileCollection
  alias BlueJet.FileStorage.ExternalFileCollectionMembership

  schema "external_file_collections" do
    field :account_id, Ecto.UUID
    field :status, :string, default: "active"
    field :code, :string
    field :name, :string
    field :label, :string

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, defualt: %{}

    field :owner_id, Ecto.UUID
    field :owner_type, :string

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
    |> validate_required([:account_id, :name])
    |> foreign_key_constraint(:account_id)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params, locale, default_locale) do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  def file_count(%ExternalFileCollection{ id: efc_id }) do
    from(efcm in ExternalFileCollectionMembership,
      select: count(efcm.id),
      where: efcm.collection_id == ^efc_id)
    |> Repo.one()
  end

  defmodule Query do
    use BlueJet, :query

    def default() do
      from(efc in ExternalFileCollection, order_by: [desc: efc.updated_at])
    end

    def for_owner_type(owner_type) do
      from(efc in ExternalFileCollection, where: efc.owner_type == ^owner_type, order_by: [desc: efc.updated_at])
    end

    def for_account(query, account_id) do
      from(efc in query, where: efc.account_id == ^account_id)
    end

    def preloads({:files, ef_preloads}, options) do
      query = ExternalFile.Query.default() |> ExternalFile.Query.uploaded()
      [files: {query, ExternalFile.Query.preloads(ef_preloads, options)}]
    end
  end
end
