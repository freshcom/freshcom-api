defmodule BlueJet.FileStorage.FileCollection do
  use BlueJet, :data

  alias BlueJet.FileStorage.{File, FileCollectionMembership}
  alias __MODULE__.Proxy

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

    field :file_count, :integer, virtual: true

    timestamps()

    has_many :memberships, FileCollectionMembership, foreign_key: :collection_id
    has_many :files, through: [:memberships, :file]
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
    [
      :name,
      :caption,
      :description,
      :custom_data
    ]
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  @spec changeset(__MODULE__.t(), atom, map) :: Changeset.t()
  def changeset(file_collection, :insert, params) do
    file_collection
    |> cast(params, writable_fields())
    |> Map.put(:action, :insert)
    |> validate()
  end

  @spec changeset(__MODULE__.t(), atom, map, String.t(), String.t()) :: Changeset.t()
  def changeset(file_collection, :update, params, locale \\ nil, default_locale \\ nil) do
    file_collection = %{ file_collection | account: Proxy.get_account(file_collection) }
    default_locale = default_locale || file_collection.account.default_locale
    locale = locale || default_locale

    file_collection
    |> cast(params, writable_fields())
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  @spec changeset(__MODULE__.t(), atom) :: Changeset.t()
  def changeset(file_collection, :delete) do
    change(file_collection)
    |> Map.put(:action, :delete)
  end

  defp validate(changeset) do
    changeset
    |> validate_required([:name, :status])
  end

  @spec put_file_urls(list | __MODULE__.t() | nil) :: list | __MODULE__.t() | nil
  def put_file_urls(nil), do: nil

  def put_file_urls(file_collections) when is_list(file_collections) do
    Enum.map(file_collections, fn(file_collection) ->
      put_file_urls(file_collection)
    end)
  end

  def put_file_urls(file_collection = %__MODULE__{}) do
    Map.put(file_collection, :files, File.put_url(file_collection.files))
  end

  @spec create_memberships_for_file_ids(__MODULE__.t()) :: {:ok, __MODULE__.t()}
  def create_memberships_for_file_ids(file_collection) do
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

  @spec file_count(__MODULE__.t()) :: integer
  def file_count(%__MODULE__{ id: collection_id }) do
    FileCollectionMembership.Query.default()
    |> FileCollectionMembership.Query.for_collection(collection_id)
    |> FileCollectionMembership.Query.with_file_status("uploaded")
    |> Repo.aggregate(:count, :id)
  end

  @spec put_file_count(list | __MODULE__.t() | nil) :: list | __MODULE__.t() | nil
  def put_file_count(nil), do: nil

  def put_file_count(file_collections) when is_list(file_collections) do
    Enum.map(file_collections, fn(file_collection) ->
      put_file_count(file_collection)
    end)
  end

  def put_file_count(file_collection) do
    %{ file_collection | file_count: file_count(file_collection) }
  end
end
