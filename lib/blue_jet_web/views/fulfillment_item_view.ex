defmodule BlueJetWeb.FulfillmentItemView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :status,
    :code,
    :name,
    :label,

    :print_name,
    :quantity,
    :returned_quantity,
    :gross_quantity,

    :caption,
    :description,
    :custom_data,

    :inserted_at,
    :updated_at
  ]

  has_one :package, serializer: BlueJetWeb.FulfillmentPackageView, identifiers: :always
  has_one :order_line_item, serializer: BlueJetWeb.IdentifierView, identifiers: :always
  has_one :goods, serializer: BlueJetWeb.IdentifierView, identifiers: :always
  has_one :target, serializer: BlueJetWeb.IdentifierView, identifiers: :always

  def type do
    "FulfillmentItem"
  end

  def package(%{ package_id: nil }, _), do: nil
  def package(%{ package_id: package_id, package: %Ecto.Association.NotLoaded{} }, _), do: %{ id: package_id, type: "FulfillmentPackage" }
  def package(%{ package: package }, _), do: package

  def source(%{ source_id: nil }, _), do: nil
  def source(%{ source_id: source_id, source_type: source_type, source: nil }, _), do: %{ id: source_id, type: source_type }
  def source(%{ source: source }, _), do: source

  def target(%{ target_id: nil }, _), do: nil
  def target(%{ target_id: target_id, target_type: target_type, target: nil }, _), do: %{ id: target_id, type: target_type }
  def target(%{ target: target }, _), do: target

  def order_line_item(%{ order_line_item_id: nil }, _), do: nil
  def order_line_item(%{ order_line_item_id: order_line_item_id, order_line_item: nil }, _), do: %{ id: order_line_item_id, type: "OrderLineItem" }
  def order_line_item(%{ order_line_item: order_line_item }, _), do: order_line_item
end
