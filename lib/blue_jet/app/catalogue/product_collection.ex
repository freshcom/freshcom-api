defmodule BlueJet.Catalogue.ProductCollection do
  use BlueJet, :data

  alias __MODULE__.Proxy
  alias BlueJet.Catalogue.ProductCollectionMembership

  schema "product_collections" do
    field :account_id, Ecto.UUID
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

    field :avatar_id, Ecto.UUID
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

  def changeset(product_collection, :insert, params) do
    product_collection
    |> cast(params, writable_fields())
    |> validate()
  end

  def changeset(product_collection, :update, params, locale \\ nil, default_locale \\ nil) do
    product_collection = Proxy.put_account(product_collection)
    default_locale = default_locale || product_collection.account.default_locale
    locale = locale || default_locale

    product_collection
    |> cast(params, writable_fields())
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  def changeset(product_collection, :delete) do
    change(product_collection)
    |> Map.put(:action, :delete)
  end

  @spec validate(Changeset.t()) :: Changeset.t()
  def validate(changeset) do
    changeset
    |> validate_required([:status, :name])
  end

  def delete_avatar(product_collection) do
    Proxy.delete_avatar(product_collection)

    {:ok, product_collection}
  end

  def product_count(%__MODULE__{id: collection_id}) do
    ProductCollectionMembership.Query.default()
    |> ProductCollectionMembership.Query.for_collection(collection_id)
    |> Repo.aggregate(:count, :id)
  end

  def put_product_count(nil), do: nil

  def put_product_count(product_collections) when is_list(product_collections) do
    Enum.map(product_collections, fn product_collection ->
      put_product_count(product_collection)
    end)
  end

  def put_product_count(product_collection) do
    %{product_collection | product_count: product_count(product_collection)}
  end
end
