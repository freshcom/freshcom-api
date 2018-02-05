defmodule BlueJet.FileStorage.FileCollection do
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias BlueJet.FileStorage.{File, FileCollectionMembership}
  alias BlueJet.FileStorage.FileCollection.Proxy

  schema "file_collections" do
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

    field :file_ids, {:array, Ecto.UUID}, default: [], virtual: true

    field :owner_id, Ecto.UUID
    field :owner_type, :string

    timestamps()

    has_many :file_memberships, FileCollectionMembership, foreign_key: :collection_id
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
    (__MODULE__.__schema__(:fields) -- @system_fields) ++ [:file_ids]
  end

  def translatable_fields do
    __MODULE__.__trans__(:fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required([:name, :status])
  end

  def put_file_urls(efc, opts \\ [])

  def put_file_urls(efcs, opts) when is_list(efcs) do
    Enum.map(efcs, fn(efc) ->
      put_file_urls(efc, opts)
    end)
  end

  def put_file_urls(efc = %__MODULE__{}, opts) do
    Map.put(efc, :files, File.put_url(efc.files, opts))
  end
  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(file_collection, :insert, params) do
    file_collection
    |> cast(params, writable_fields())
    |> Map.put(:action, :insert)
    |> validate()
  end

  def changeset(file_collection, :update, params, locale \\ nil, default_locale \\ nil) do
    file_collection = %{ file_collection | account: Proxy.get_account(file_collection) }
    default_locale = default_locale || file_collection.account.default_locale
    locale = locale || default_locale

    file_collection
    |> cast(params, writable_fields())
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  def changeset(file_collection, :delete) do
    change(file_collection)
    |> Map.put(:action, :delete)
  end

  def process(file_collection, %{ action: :insert }) do
    sort_index_step = 10000

    Enum.reduce(file_collection.file_ids, 10000, fn(file_id, acc) ->
      Repo.insert!(%FileCollectionMembership{
        account_id: file_collection.account_id,
        collection_id: file_collection.id,
        file_id: file_id,
        sort_index: acc
      })

      acc + sort_index_step
    end)

    {:ok, file_collection}
  end

  def file_count(%__MODULE__{ id: efc_id }) do
    from(efcm in FileCollectionMembership,
      select: count(efcm.id),
      where: efcm.collection_id == ^efc_id)
    |> Repo.one()
  end
end
