defmodule BlueJet.Storefront.Product do
  use BlueJet, :data

  use Trans, translates: [:name, :caption, :description, :custom_data], container: :translations

  alias Ecto.Changeset

  alias BlueJet.Translation
  alias BlueJet.Storefront.ProductItem
  alias BlueJet.Storefront.Product
  alias BlueJet.Storefront.Price
  alias BlueJet.Identity.Account
  alias BlueJet.FileStorage.ExternalFile
  alias BlueJet.FileStorage.ExternalFileCollection

  schema "products" do
    field :name, :string
    field :print_name, :string
    field :status, :string
    field :item_mode, :string, default: "any"
    field :caption, :string
    field :description, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :account, Account
    belongs_to :avatar, ExternalFile
    has_many :items, ProductItem, on_delete: :delete_all
    has_many :external_file_collections, ExternalFileCollection, on_delete: :delete_all
    has_many :prices, Price, on_delete: :delete_all
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
    writable_fields() -- [:account_id, :item_mode]
  end

  def validate(changeset) do
    changeset
    |> validate_required([:account_id, :name, :status, :item_mode])
    |> validate_assoc_account_scope(:avatar)
    |> validate_status()
  end

  def validate_status(changeset) do
    item_mode = get_field(changeset, :item_mode)
    validate_status(changeset, item_mode)
  end
  def validate_status(changeset), do: changeset

  defp validate_status(changeset = %Changeset{ changes: %{ status: "active" } }, "any") do
    product_id = get_field(changeset, :id)
    active_primary_item = Repo.get_by(ProductItem, product_id: product_id, status: "active", primary: true)

    case active_primary_item do
      nil -> Changeset.add_error(changeset, :status, "A Product must have a Primary Active Item in order to be marked Active.", [validation: "require_primary_active_item", full_error_message: true])
      _ -> changeset
    end
  end
  defp validate_status(changeset = %Changeset{ changes: %{ status: "active" } }, "all") do
    product_items = Ecto.assoc(changeset.data, :items)
    product_item_count = product_items |> Repo.aggregate(:count, :id)
    active_pi_count = from(pi in product_items, where: pi.status == "active") |> Repo.aggregate(:count, :id)

    prices = Ecto.assoc(changeset.data, :prices)
    active_price_count = from(p in prices, where: p.status == "active") |> Repo.aggregate(:count, :id)

    cond do
      active_pi_count != product_item_count -> Changeset.add_error(changeset, :status, "A Product with Item Mode set to All must have all of its Item set to Active in order to be marked Active.", [validation: "require_all_item_active", full_error_message: true])
      active_price_count == 0 -> Changeset.add_error(changeset, :status, "A Product with Item Mode set to All require at least one Active Price in order to be marked Active.", [validation: "require_at_least_one_active_price", full_error_message: true])
      true -> changeset
    end
  end
  defp validate_status(changeset = %Changeset{ changes: %{ status: "internal" } }, "any") do
    product_items = Ecto.assoc(changeset.data, :items)
    active_or_internal_product_items = from(pi in product_items, where: pi.status in ["active", "internal"])
    aipi_count = Repo.aggregate(active_or_internal_product_items, :count, :id)

    case aipi_count do
      0 -> Changeset.add_error(changeset, :status, "A Product must have at least one Active/Internal Item in order to be marked Internal.", [validation: "require_at_least_one_internal_item", full_error_message: true])
      _ -> changeset
    end
  end
  defp validate_status(changeset = %Changeset{ changes: %{ status: "internal" } }, "all") do
    product_items = Ecto.assoc(changeset.data, :items)
    product_item_count = product_items |> Repo.aggregate(:count, :id)
    ai_pi_count = from(pi in product_items, where: pi.status in ["active", "internal"]) |> Repo.aggregate(:count, :id)

    prices = Ecto.assoc(changeset.data, :prices)
    ai_price_count = from(p in prices, where: p.status in ["active", "internal"]) |> Repo.aggregate(:count, :id)

    cond do
      ai_pi_count != product_item_count -> Changeset.add_error(changeset, :status, "A Product with Item Mode set to All must have all of its Item set to Active/Internal in order to be marked Internal.", [validation: "require_all_item_internal", full_error_message: true])
      ai_price_count == 0 -> Changeset.add_error(changeset, :status, "A Product with Item Mode set to All require at least one Active/Internal Price in order to be marked Internal.", [validation: "require_at_least_one_internal_price", full_error_message: true])
      true -> changeset
    end
  end
  defp validate_status(changeset, item_mode), do: changeset

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> Translation.put_change(translatable_fields(), locale)
  end

  def query() do
    from(p in Product, order_by: [desc: :updated_at])
  end

  def preload(struct_or_structs, targets) when length(targets) == 0 do
    struct_or_structs
  end
  def preload(struct_or_structs, targets) when is_list(targets) do
    [target | rest] = targets

    struct_or_structs
    |> Repo.preload(preload_keyword(target))
    |> Product.preload(rest)
  end

  def preload_keyword(:items) do
    [items: ProductItem.query()]
  end
  def preload_keyword({:items, item_preloads}) do
    [items: {ProductItem.query(), ProductItem.preload_keyword(item_preloads)}]
  end
  def preload_keyword(:avatar) do
    :avatar
  end
  def preload_keyword(:external_file_collections) do
    [external_file_collections: ExternalFileCollection.query()]
  end
  def preload_keyword(:prices) do
    [prices: Price.query()]
  end
end
