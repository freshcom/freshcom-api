defmodule BlueJetWeb.ProductItemView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  alias BlueJet.Repo

  attributes [:code, :status, :short_name, :name_sync, :name, :sort_index, :source_quantity, :maximum_public_order_quantity,
    :primary, :print_name, :custom_data, :locale, :inserted_at, :updated_at]

  has_one :product, serializer: BlueJetWeb.ProductView, identifiers: :always
  has_one :sku, serializer: BlueJetWeb.SkuView, identifiers: :always
  has_one :unlockable, serializer: BlueJetWeb.UnlockableView, identifiers: :always
  has_one :default_price, serializer: BlueJetWeb.PriceView, identifiers: :when_included
  has_many :prices, serializer: BlueJetWeb.PriceView, identifiers: :when_included

  def type(_, _) do
    "ProductItem"
  end

  def locale(_, %{ assigns: %{ locale: locale } }), do: locale

  def product(struct, conn) do
    case struct.product do
      %Ecto.Association.NotLoaded{} ->
        struct
        |> Ecto.assoc(:product)
        |> Repo.one()
      other -> other
    end
  end

  def sku(struct, conn) do
    case struct.sku do
      %Ecto.Association.NotLoaded{} ->
        struct
        |> Ecto.assoc(:sku)
        |> Repo.one()
      other -> other
    end
  end

  def unlockable(struct, conn) do
    case struct.unlockable do
      %Ecto.Association.NotLoaded{} ->
        struct
        |> Ecto.assoc(:unlockable)
        |> Repo.one()
      other -> other
    end
  end

  def default_price(struct, _) do
    ProductItem.default_price(struct)
  end
end
