defmodule BlueJetWeb.ReturnItemView do
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

  # has_one :package, serializer: BlueJetWeb.FulfillmentPackageView, identifiers: :always
  has_one :fulfillment_item, serializer: BlueJetWeb.FulfillmentItemView, identifiers: :always
  has_one :source, serializer: BlueJetWeb.IdentifierView, identifiers: :always
  has_one :target, serializer: BlueJetWeb.IdentifierView, identifiers: :always

  def type do
    "ReturnItem"
  end

  def package(%{ package_id: nil }, _), do: nil
  def package(%{ package_id: package_id, package: %Ecto.Association.NotLoaded{} }, _), do: %{ id: package_id, type: "ReturnPackage" }
  def package(%{ package: package }, _), do: package

  def source(%{ source_id: nil }, _), do: nil
  def source(%{ source_id: source_id, source_type: source_type, source: nil }, _), do: %{ id: source_id, type: source_type }
  def source(%{ source: source }, _), do: source

  def target(%{ target_id: nil }, _), do: nil
  def target(%{ target_id: target_id, target_type: target_type, target: nil }, _), do: %{ id: target_id, type: target_type }
  def target(%{ target: target }, _), do: target

  def fulfillment_item(%{ fulfillment_item_id: nil }, _), do: nil
  def fulfillment_item(%{ fulfillment_item_id: fulfillment_item_id, fulfillment_item: nil }, _), do: %{ id: fulfillment_item_id, type: "FulfillmentItem" }
  def fulfillment_item(%{ fulfillment_item: fulfillment_item }, _), do: fulfillment_item
end
