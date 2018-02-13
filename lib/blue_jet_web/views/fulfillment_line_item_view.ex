defmodule BlueJetWeb.FulfillmentLineItemView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :status,
    :code,
    :name,
    :label,

    :print_name,
    :quantity,

    :caption,
    :description,
    :custom_data,

    :inserted_at,
    :updated_at
  ]

  has_one :fulfillment, serializer: BlueJetWeb.FulfillmentView, identifiers: :always
  has_one :order_line_item, serializer: BlueJetWeb.IdentifierView, identifiers: :always
  has_one :goods, serializer: BlueJetWeb.IdentifierView, identifiers: :always
  has_one :target, serializer: BlueJetWeb.IdentifierView, identifiers: :always

  def type do
    "FulfillmentLineItem"
  end

  def fulfillment(%{ fulfillment_id: nil }, _), do: nil
  def fulfillment(%{ fulfillment_id: fulfillment_id, fulfillment: %Ecto.Association.NotLoaded{} }, _), do: %{ id: fulfillment_id, type: "Fulfillment" }
  def fulfillment(%{ fulfillment: fulfillment }, _), do: fulfillment

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
