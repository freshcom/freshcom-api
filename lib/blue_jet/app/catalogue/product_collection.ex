defmodule BlueJet.Catalogue.ProductCollection do
  @behaviour BlueJet.Data

  use BlueJet, :data

  alias __MODULE__.Proxy
  alias BlueJet.Catalogue.ProductCollectionMembership

  schema "product_collections" do
    field :account_id, UUID
    field :account, :map, virtual: true

    field :status, :string, default: "draft"
    field :code, :string
    field :name, :string
    field :label, :string
    field :sort_index, :integer, default: 0

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, defualt: %{}

    field :avatar_id, UUID
    field :avatar, :map, virtual: true

    field :product_count, :integer, virtual: true

    timestamps()

    has_many :memberships, ProductCollectionMembership, foreign_key: :collection_id
    has_many :products, through: [:memberships, :product]
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

  def translatable_fields do
    [
      :name,
      :caption,
      :description,
      :custom_data
    ]
  end

  @spec changeset(__MODULE__.t(), :insert, map) :: Changeset.t()
  def changeset(collection, action, fields)
  def changeset(collection, :insert, params) do
    collection
    |> cast(params, writable_fields())
    |> validate()
  end

  @spec changeset(__MODULE__.t(), :update, map, String.t() | nil) :: Changeset.t()
  def changeset(collection, action, fields, locale \\ nil)
  def changeset(collection, :update, params, locale) do
    collection = Proxy.put_account(collection)
    default_locale = collection.account.default_locale
    locale = locale || default_locale

    collection
    |> cast(params, writable_fields())
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  @spec changeset(__MODULE__.t(), :delete) :: Changeset.t()
  def changeset(collection, action)
  def changeset(collection, :delete) do
    change(collection)
    |> Map.put(:action, :delete)
  end

  @spec validate(Changeset.t()) :: Changeset.t()
  def validate(changeset) do
    changeset
    |> validate_required([:status, :name])
  end

  def product_count(%__MODULE__{id: collection_id}) do
    ProductCollectionMembership.Query.default()
    |> ProductCollectionMembership.Query.for_collection(collection_id)
    |> Repo.aggregate(:count, :id)
  end

  def put_product_count(nil), do: nil

  def put_product_count(collections) when is_list(collections) do
    Enum.map(collections, fn collection ->
      put_product_count(collection)
    end)
  end

  def put_product_count(collection) do
    %{collection | product_count: product_count(collection)}
  end
end
