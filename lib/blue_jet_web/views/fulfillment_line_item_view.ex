defmodule BlueJetWeb.FulfillmentLineItemView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :code,
    :name,
    :label,

    :print_name,

    :caption,
    :description,
    :custom_data,

    :inserted_at,
    :updated_at
  ]

  has_one :fulfillment, serializer: BlueJetWeb.FulfillmentView, identifiers: :always
  has_one :goods, serializer: BlueJetWeb.IdentifierView, identifiers: :always
  has_one :source, serializer: BlueJetWeb.IdentifierView, identifiers: :always

  def type do
    "FulfillmentLineItem"
  end

  def fulfillment(%{ fulfillment_id: nil }, _), do: nil
  def fulfillment(%{ fulfillment_id: fulfillment_id, fulfillment: %Ecto.Association.NotLoaded{} }, _), do: %{ id: fulfillment_id, type: "Customer" }
  def fulfillment(%{ fulfillment: fulfillment }, _), do: fulfillment

  def source(%{ source_id: nil }, _), do: nil
  def source(%{ source_id: source_id, source_type: source_type, source: nil }, _), do: %{ id: source_id, type: source_type }
  def source(%{ source: source }, _), do: source

  def goods(%{ goods_id: nil }, _), do: nil
  def goods(%{ goods_id: goods_id, goods_type: goods_type, goods: nil }, _), do: %{ id: goods_id, type: goods_type }
  def goods(%{ goods: goods }, _), do: goods
end
