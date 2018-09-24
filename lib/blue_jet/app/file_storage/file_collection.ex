defmodule BlueJet.FileStorage.FileCollection do
  @behaviour BlueJet.Data

  use BlueJet, :data

  alias BlueJet.FileStorage.{File, FileCollectionMembership}
  alias __MODULE__.Proxy

  schema "file_collections" do
    field :account_id, UUID
    field :account, :map, virtual: true

    field :status, :string, default: "active"
    field :code, :string
    field :name, :string
    field :label, :string

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, defualt: %{}

    field :file_ids, {:array, UUID}, default: [], virtual: true

    field :owner_id, UUID
    field :owner_type, :string

    field :file_count, :integer, virtual: true

    timestamps()

    has_many :memberships, FileCollectionMembership, foreign_key: :collection_id
    has_many :files, through: [:memberships, :file]
  end

  @type t :: Ecto.Schema.t()

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
    [
      :name,
      :caption,
      :description,
      :custom_data
    ]
  end

  @doc """
  Builds a changeset based on the `struct` and `fields`.
  """
  @spec changeset(__MODULE__.t(), atom, map) :: Changeset.t()
  def changeset(collection, action, fields)
  def changeset(collection, :insert, fields) do
    collection
    |> cast(fields, writable_fields())
    |> Map.put(:action, :insert)
    |> validate()
  end

  @spec changeset(__MODULE__.t(), atom, map, String.t() | nil) :: Changeset.t()
  def changeset(collection, action, fields, locale \\ nil)
  def changeset(collection, :update, fields, locale) do
    collection = %{collection | account: Proxy.get_account(collection)}
    default_locale = collection.account.default_locale
    locale = locale || default_locale

    collection
    |> cast(fields, writable_fields())
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  @spec changeset(__MODULE__.t(), atom) :: Changeset.t()
  def changeset(collection, action)
  def changeset(collection, :delete) do
    change(collection)
    |> Map.put(:action, :delete)
  end

  @spec validate(Changeset.t()) :: Changeset.t()
  def validate(changeset) do
    changeset
    |> validate_required([:name, :status])
  end

  @spec put_file_urls(list | __MODULE__.t() | nil) :: list | __MODULE__.t() | nil
  def put_file_urls(nil), do: nil

  def put_file_urls(collections) when is_list(collections) do
    Enum.map(collections, fn collection ->
      put_file_urls(collection)
    end)
  end

  def put_file_urls(collection = %__MODULE__{}) do
    Map.put(collection, :files, File.put_url(collection.files))
  end

  @spec file_count(__MODULE__.t()) :: integer
  def file_count(%__MODULE__{id: collection_id}) do
    FileCollectionMembership.Query.default()
    |> FileCollectionMembership.Query.for_collection(collection_id)
    |> FileCollectionMembership.Query.with_file_status("uploaded")
    |> Repo.aggregate(:count, :id)
  end

  @spec put_file_count(list | __MODULE__.t() | nil) :: list | __MODULE__.t() | nil
  def put_file_count(nil), do: nil

  def put_file_count(collections) when is_list(collections) do
    Enum.map(collections, fn collection ->
      put_file_count(collection)
    end)
  end

  def put_file_count(collection) do
    %{collection | file_count: file_count(collection)}
  end
end
