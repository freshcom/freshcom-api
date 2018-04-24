defmodule BlueJetWeb.FulfillmentPackageView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :status,
    :code,
    :name,
    :label,
    :system_label,

    :caption,
    :description,
    :custom_data,

    :inserted_at,
    :updated_at
  ]

  has_one :source, serializer: BlueJetWeb.IdentifierView, identifiers: :always
  has_one :order, serializer: BlueJetWeb.OrderView, identifiers: :always
  has_one :customer, serializer: BlueJetWeb.CustomerView, identifiers: :always

  has_many :items, serializer: BlueJetWeb.FulfillmentItemView, identifiers: :when_included
  has_many :file_collections, serializer: BlueJetWeb.FileCollectionView, identifiers: :when_included

  def type do
    "FulfillmentPackage"
  end

  def order(%{ order_id: nil }, _), do: nil
  def order(%{ order_id: order_id, order: nil }, _), do: %{ id: order_id, type: "Order" }
  def order(%{ order: order }, _), do: order

  def customer(%{ customer_id: nil }, _), do: nil
  def customer(%{ customer_id: customer_id, customer: nil }, _), do: %{ id: customer_id, type: "Order" }
  def customer(%{ customer: customer }, _), do: customer
end
