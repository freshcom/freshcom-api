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
    Map.put(efc, :files, File.put_url(efc.files, opts))
  end
  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(efc, params, locale \\ nil, default_locale \\ nil) do
    efc = %{ efc | account: Proxy.get_account(efc) }
    default_locale = default_locale || efc.account.default_locale
    locale = locale || default_locale

    efc
    |> cast(params, writable_fields())
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  def file_count(%__MODULE__{ id: efc_id }) do
    from(efcm in FileCollectionMembership,
      select: count(efcm.id),
      where: efcm.collection_id == ^efc_id)
    |> Repo.one()
  end
end
