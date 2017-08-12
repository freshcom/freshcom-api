defmodule BlueJet.Storefront.ProductItem do
  use BlueJet, :data

  use Trans, translates: [:name, :short_name, :custom_data], container: :translations

  alias BlueJet.Translation
  alias BlueJet.Storefront.ProductItem
  alias BlueJet.Storefront.Product
  alias BlueJet.Identity.Account
  alias BlueJet.Inventory.Sku
  alias BlueJet.Inventory.Unlockable

  schema "product_items" do
    field :code, :string
    field :status, :string
    field :short_name, :string
    field :sort_index, :integer, default: 9999
    field :source_quantity, :integer, default: 1
    field :maximum_public_order_quantity, :integer, default: 9999
    field :primary, :boolean, default: false

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :account, Account
    belongs_to :product, Product
    belongs_to :sku, Sku
    belongs_to :unlockable, Unlockable
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    ProductItem.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    ProductItem.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id, :product_id]
  end

  def required_fields do
    [
      :status, :sort_index, :source_quantity, :maximum_public_order_quantity, :primary,
      :custom_data, :product_id
    ]
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields())
    |> validate_required_exactly_one([:sku_id, :unlockable_id], :relationships)
    |> validate_assoc_account_scope([:product, :sku, :unlockable])
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> put_name()
    |> Translation.put_change(translatable_fields(), locale)
  end

  def put_name(changeset = %Changeset{ valid?: true, changes: %{ product_id: product_id } }) do
    product = Repo.get!(Product, product_id)
    short_name = Changeset.get_field(changeset, :short_name)
    put_change(changeset, :name, "#{product.name} #{short_name}")
  end

  def query_for(product_id: product_id) do
    query = from pi in ProductItem,
      where: pi.product_id == ^product_id

    query
  end
end
