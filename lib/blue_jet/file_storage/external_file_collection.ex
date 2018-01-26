defmodule BlueJet.FileStorage.ExternalFileCollection do
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias BlueJet.FileStorage.IdentityService
  alias BlueJet.FileStorage.{ExternalFile, ExternalFileCollectionMembership}

  schema "external_file_collections" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

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

  def translatable_fields do
    __MODULE__.__trans__(:fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required([:name])
  end

  def put_file_urls(efc, opts \\ [])

  def put_file_urls(efcs, opts) when is_list(efcs) do
    Enum.map(efcs, fn(efc) ->
      put_file_urls(efc, opts)
    end)
  end

  def put_file_urls(efc = %__MODULE__{}, opts) do
    Map.put(efc, :files, ExternalFile.put_url(efc.files, opts))
  end
  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(efc, params, locale \\ nil, default_locale \\ nil) do
    efc = %{ efc | account: get_account(efc) }
    default_locale = default_locale || efc.account.default_locale
    locale = locale || default_locale

    efc
    |> cast(params, writable_fields())
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  def file_count(%__MODULE__{ id: efc_id }) do
    from(efcm in ExternalFileCollectionMembership,
      select: count(efcm.id),
      where: efcm.collection_id == ^efc_id)
    |> Repo.one()
  end

  def get_account(efc) do
    efc.account || IdentityService.get_account(efc)
  end

  defmodule Query do
    use BlueJet, :query

    alias BlueJet.FileStorage.ExternalFileCollection

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
