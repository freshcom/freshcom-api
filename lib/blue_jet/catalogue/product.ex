defmodule BlueJet.Catalogue.Product do
  @moduledoc """
  Product kinds:
  - simple
  - combo
  - with_variants
  """

  use BlueJet, :data

  use Trans, translates: [:name, :caption, :description, :custom_data], container: :translations

  alias Ecto.Changeset

  alias BlueJet.AccessRequest
  alias BlueJet.AccessResponse
  alias BlueJet.Translation

  alias BlueJet.Goods

  alias BlueJet.Catalogue.ProductItem
  alias BlueJet.Catalogue.Product
  alias BlueJet.Catalogue.Price
  alias BlueJet.FileStorage.ExternalFile
  alias BlueJet.FileStorage.ExternalFileCollection

  schema "products" do
    field :account_id, Ecto.UUID

    field :kind, :string, default: "simple"
    field :status, :string, default: "draft"

    field :name_sync, :string, default: "disabled"
    field :name, :string
    field :short_name, :string
    field :print_name, :string

    field :sort_index, :integer
    field :source_quantity, :integer
    field :maximum_public_order_quantity, :integer
    field :primary, :boolean, default: false

    field :caption, :string
    field :description, :string

    field :source_id, Ecto.UUID
    field :source_type, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :avatar, ExternalFile
    belongs_to :parent, Product
    has_many :items, Product, foreign_key: :parent_id, on_delete: :delete_all
    has_many :variants, Product, foreign_key: :parent_id, on_delete: :delete_all

    has_many :external_file_collections, ExternalFileCollection, foreign_key: :owner_id, on_delete: :delete_all
    has_many :prices, Price, on_delete: :delete_all
    has_one :default_price, Price
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    Product.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    Product.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id, :kind]
  end

  def required_fields(changeset) do
    kind = get_field(changeset, :kind)

    common = [:account_id, :kind, :status, :name_sync, :name, :primary]
    case kind do
      "simple" -> common ++ [:source_quantity, :maximum_public_order_quantity, :source_id, :source_type]
      "with_variants" -> common
      "combo" -> common ++ [:maximum_public_order_quantity]
      "variant" -> common ++ [:parent_id, :source_quantity, :maximum_public_order_quantity, :sort_index, :source_id, :source_type]
      "item" -> common ++ [:parent_id, :source_quantity, :sort_index, :source_id, :source_type]
      _ -> common
    end
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields(changeset))
    |> validate_assoc_account_scope(:avatar)
    |> validate_status()
    |> validate_source()
  end

  def validate_source(changeset) do
    kind = get_field(changeset, :kind)
    validate_source(changeset, kind)
  end
  defp validate_source(changeset, "with_variants"), do: changeset
  defp validate_source(changeset, "combo"), do: changeset
  defp validate_source(changeset, _) do
    source_id = get_field(changeset, :source_id)
    source_type = get_field(changeset, :source_type)
    account_id = get_field(changeset, :account_id)

    case source(account_id, source_id, source_type) do
      nil -> Changeset.add_error(changeset, :source_id, "is invalid")
      _ -> changeset
    end
  end

  def validate_status(changeset) do
    kind = get_field(changeset, :kind)
    validate_status(changeset, kind)
  end
  def validate_status(changeset), do: changeset

  defp validate_status(changeset = %Changeset{ changes: %{ status: "active" } }, "variant") do
    validate_status(changeset, "simple")
  end
  defp validate_status(changeset = %Changeset{ changes: %{ status: "active" } }, "simple") do
    id = get_field(changeset, :id)

    active_price = if id do
      Repo.get_by(Price, product_id: id, status: "active")
    else
      nil
    end

    case active_price do
      nil -> Changeset.add_error(changeset, :status, "A Product must have a Active Price in order to be marked Active.", [validation: "require_active_price", full_error_message: true])
      _ -> changeset
    end
  end
  defp validate_status(changeset = %Changeset{ changes: %{ status: "active" } }, "with_variants") do
    id = get_field(changeset, :id)

    active_primary_item = if id do
      Repo.get_by(Product, parent_id: id, status: "active", primary: true)
    else
      nil
    end

    case active_primary_item do
      nil -> Changeset.add_error(changeset, :status, "A Product with variants must have a Primary Active Variant in order to be marked Active.", [validation: "require_primary_active_variant", full_error_message: true])
      _ -> changeset
    end
  end
  defp validate_status(changeset = %Changeset{ changes: %{ status: "active" } }, "combo") do
    items = Ecto.assoc(changeset.data, :items)
    item_count = Ecto.assoc(changeset.data, :items) |> Repo.aggregate(:count, :id)
    active_item_count = from(p in items, where: p.status == "active") |> Repo.aggregate(:count, :id)

    prices = Ecto.assoc(changeset.data, :prices)
    active_price_count = from(p in prices, where: p.status == "active") |> Repo.aggregate(:count, :id)

    cond do
      active_item_count != item_count -> Changeset.add_error(changeset, :status, "A Product combo must have all of its Item set to Active in order to be marked Active.", [validation: "require_all_item_active", full_error_message: true])
      active_price_count == 0 -> Changeset.add_error(changeset, :status, "A Product Combo require at least one Active Price in order to be marked Active.", [validation: "require_at_least_one_active_price", full_error_message: true])
      true -> changeset
    end
  end
  defp validate_status(changeset = %Changeset{ changes: %{ status: "internal" } }, "variant") do
    validate_status(changeset, "simple")
  end
  defp validate_status(changeset = %Changeset{ changes: %{ status: "internal" } }, "simple") do
    prices = Ecto.assoc(changeset.data, :prices)
    ai_price_count = from(p in prices, where: p.status in ["active", "internal"]) |> Repo.aggregate(:count, :id)

    if ai_price_count > 0 do
      changeset
    else
      Changeset.add_error(changeset, :status, "A Product must have a Active/Internal Price in order to be marked Internal.", [validation: "require_internal_price", full_error_message: true])
    end
  end
  defp validate_status(changeset = %Changeset{ changes: %{ status: "internal" } }, "with_variants") do
    variants = Ecto.assoc(changeset.data, :variants)
    active_or_internal_variants = from(p in variants, where: p.status in ["active", "internal"])
    aiv_count = Repo.aggregate(active_or_internal_variants, :count, :id)

    case aiv_count do
      0 -> Changeset.add_error(changeset, :status, "A Product with variants must have at least one Active/Internal Variant in order to be marked Internal.", [validation: "require_at_least_one_internal_variant", full_error_message: true])
      _ -> changeset
    end
  end
  defp validate_status(changeset = %Changeset{ changes: %{ status: "internal" } }, "combo") do
    items = Ecto.assoc(changeset.data, :items)
    item_count = items |> Repo.aggregate(:count, :id)
    aip_count = from(p in items, where: p.status in ["active", "internal"]) |> Repo.aggregate(:count, :id)

    prices = Ecto.assoc(changeset.data, :prices)
    ai_price_count = from(p in prices, where: p.status in ["active", "internal"]) |> Repo.aggregate(:count, :id)

    cond do
      aip_count != item_count -> Changeset.add_error(changeset, :status, "A Product combo must have all of its Item set to Active/Internal in order to be marked Internal.", [validation: "require_all_item_internal", full_error_message: true])
      ai_price_count == 0 -> Changeset.add_error(changeset, :status, "A Product combo require at least one Active/Internal Price in order to be marked Internal.", [validation: "require_at_least_one_internal_price", full_error_message: true])
      true -> changeset
    end
  end
  defp validate_status(changeset, kind), do: changeset

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> put_name(locale)
    |> validate()
    |> Translation.put_change(translatable_fields(), locale)
  end

  def source(account_id, source_id, "Stockable") do
    response = Goods.do_get_stockable(%AccessRequest{
      vas: %{ account_id: account_id },
      params: %{ id: source_id }
    })

    case response do
      {:ok, %{ data: stockable }} -> stockable
      {:error, _} -> nil
    end
  end
  def source(account_id, source_id, "Unlockable") do
    response = Goods.do_get_unlockable(%AccessRequest{
      vas: %{ account_id: account_id },
      params: %{ id: source_id }
    })

    case response do
      {:ok, %{ data: unlockable }} -> unlockable
      {:error, _} -> nil
    end
  end
  def source(account_id, source_id, "Depositable") do
    response = Goods.do_get_depositable(%AccessRequest{
      vas: %{ account_id: account_id },
      params: %{ id: source_id }
    })

    case response do
      {:ok, %{ data: unlockable }} -> unlockable
      {:error, _} -> nil
    end
  end
  def source(_, _, _), do: nil

  def put_name(changeset = %Changeset{ valid?: true, changes: %{ name_sync: "sync_with_source" } }, _) do
    source_id = get_field(changeset, :source_id)
    source_type = get_field(changeset, :source_type)
    account_id = get_field(changeset, :account_id)
    source = source(account_id, source_id, source_type)

    if source do
      changeset = put_change(changeset, :name, "#{source.name}")

      new_translations =
        changeset
        |> Changeset.get_field(:translations)
        |> Translation.merge_translations(source.translations, ["name"])

      put_change(changeset, :translations, new_translations)
    else
      changeset
    end
  end
  def put_name(changeset, _), do: changeset

  defmodule Query do
    use BlueJet, :query

    def for_account(query, account_id) do
      from(p in query, where: p.account_id == ^account_id)
    end

    def variant_default() do
      from(p in Product, where: p.kind == "variant", order_by: [desc: :updated_at])
    end
    def item_default() do
      from(p in Product, where: p.kind == "item", order_by: [desc: :updated_at])
    end

    def preloads(:items) do
      [items: Product.Query.item_default()]
    end
    def preloads({:items, item_preloads}) do
      [items: {Product.Query.item_default(), Product.Query.preloads(item_preloads)}]
    end
    def preloads(:variants) do
      [variants: Product.Query.variant_default()]
    end
    def preloads({:variants, variant_preloads}) do
      [variants: {Product.Query.variant_default(), Product.Query.preloads(variant_preloads)}]
    end
    def preloads(:prices) do
      [prices: Price.Query.default()]
    end
    def preloads(:default_price) do
      [default_price: Price.Query.active_by_moq()]
    end
    def preloads(:avatar) do
      [avatar: ExternalFile.Query.default()]
    end
    def preloads(:external_file_collections) do
      [external_file_collections: ExternalFileCollection.Query.for_owner_type("Product")]
    end

    def root(query) do
      from(p in query, where: is_nil(p.parent_id))
    end

    def default() do
      from(p in Product, order_by: [desc: :updated_at])
    end
  end
end
