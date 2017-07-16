defmodule BlueJet.ProductItem do
  use BlueJet.Web, :model
  use Trans, translates: [:short_name, :custom_data], container: :translations

  alias BlueJet.Validation
  alias BlueJet.Translation

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

    belongs_to :account, BlueJet.Account
    belongs_to :product, BlueJet.Product
    belongs_to :sku, BlueJet.Sku
    belongs_to :unlockable, BlueJet.Unlockable
  end

  def translatable_fields do
    BlueJet.ProductItem.__trans__(:fields)
  end

  def castable_fields(state) do
    all = [:account_id, :code, :status, :short_name, :sort_index, :source_quantity,
      :maximum_public_order_quantity, :primary, :custom_data, :product_id, :sku_id, :unlockable_id]

    case state do
      :built -> all
      :loaded -> all -- [:account_id]
    end
  end

  def required_fields do
    [
      :status, :sort_index, :source_quantity, :maximum_public_order_quantity, :primary,
      :custom_data, :product_id
    ]
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct = %{ __meta__: %{ state: state } }, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(state))
    |> validate_required(required_fields())
    |> Validation.validate_required_exactly_one([:sku_id, :unlockable_id], :relationships)
    |> Translation.put_change(translatable_fields(), struct.translations, locale)
  end
end
