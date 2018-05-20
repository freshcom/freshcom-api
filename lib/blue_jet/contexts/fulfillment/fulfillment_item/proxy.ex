defmodule BlueJet.Fulfillment.FulfillmentItem.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Fulfillment.IdentityService

  def get_account(fulfillment_item) do
    fulfillment_item.account || IdentityService.get_account(fulfillment_item)
  end

  def put_account(fulfillment_item) do
    %{ fulfillment_item | account: get_account(fulfillment_item) }
  end

  def put(fulfillment_item, _, _), do: fulfillment_item
end