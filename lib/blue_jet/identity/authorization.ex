defmodule BlueJet.Identity.Authorization do

  alias BlueJet.Identity.AccountMembership
  alias BlueJet.Repo

  @role_endpoints %{
    "anonymous" => [
      "identity.create_user"
    ],

    "guest" => [
      "identity.create_user",
      "identity.get_account",

      "file_storage.get_external_file",
      "file_storage.get_external_file_collection",

      "catalogue.list_product",
      "catalogue.get_product",
      "catalogue.list_product_item",
      "catalogue.get_product_item",
      "catalogue.list_price",
      "catalogue.get_price",
      "catalogue.list_product_collection",

      "crm.get_customer",
      "crm.create_customer",
      "crm.update_customer",

      "storefront.create_order",
      "storefront.get_order",
      "storefront.update_order",

      "billing.create_payment",
      "billing.get_payment",

      "storefront.create_order_line_item",
      "storefront.update_order_line_item",
      "storefront.delete_order_line_item"
    ],

    "customer" => [
      "identity.list_account",
      "identity.get_account",
      "identity.get_user",
      "identity.delete_user",

      "file_storage.get_external_file",
      "file_storage.get_external_file_collection",

      "catalogue.get_product",
      "catalogue.list_product_item",
      "catalogue.get_product_item",
      "catalogue.list_price",
      "catalogue.get_price",
      "catalogue.list_product_collection",
      "catalogue.get_product_collection",

      "crm.get_customer",
      "crm.update_customer",
      "crm.create_point_transaction",

      "storefront.list_order",
      "storefront.create_order",
      "storefront.get_order",
      "storefront.update_order",
      "storefront.list_order_line_item",
      "storefront.create_order_line_item",
      "storefront.update_order_line_item",
      "storefront.delete_order_line_item",
      "storefront.list_unlock",
      "storefront.get_unlock",

      "billing.list_payment",
      "billing.create_payment",
      "billing.get_payment",
      "billing.list_card",
      "billing.update_card",
      "billing.delete_card"
    ],

    "marketing_specialist" => [

    ],

    "support_specialist" => [
      "identity.list_account",
      "identity.get_account",
      "identity.get_user",

      "file_storage.list_external_file",
      "file_storage.create_external_file",
      "file_storage.get_external_file",
      "file_storage.update_external_file",
      "file_storage.delete_external_file",
      "file_storage.list_external_file_collection",
      "file_storage.create_external_file_collection",
      "file_storage.get_external_file_collection",
      "file_storage.update_external_file_collection",
      "file_storage.delete_external_file_collection",

      "identity.list_stockable",
      "identity.get_stockable",

      "catalogue.list_product",
      "catalogue.create_product",
      "catalogue.get_product",
      "catalogue.update_product",
      "catalogue.delete_product",
      "catalogue.list_price",
      "catalogue.create_price",
      "catalogue.get_price",
      "catalogue.update_price",
      "catalogue.delete_price",
      "catalogue.list_product_collection",
      "catalogue.create_product_collection",
      "catalogue.get_product_collection",
      "catalogue.update_product_collection",
      "catalogue.create_product_collection_membership",
      "catalogue.delete_product_collection_membership",

      "crm.list_customer",
      "crm.create_customer",
      "crm.get_customer",
      "crm.update_customer",
      "crm.delete_customer",
      "crm.create_point_transaction",

      "storefront.list_order",
      "storefront.create_order",
      "storefront.get_order",
      "storefront.update_order",
      "storefront.delete_order",
      "storefront.list_order_line_item",
      "storefront.create_order_line_item",
      "storefront.update_order_line_item",
      "storefront.delete_order_line_item",
      "storefront.list_unlock",
      "storefront.get_unlock",

      "billing.list_payment",
      "billing.create_payment",
      "billing.get_payment",
      "billing.update_payment",
      "billing.list_card",
      "billing.update_card",
      "billing.delete_card",
      "billing.create_refund"
    ],

    "inventory_specialist" => [
      "identity.list_account",
      "identity.get_account",
      "identity.get_user",

      "file_storage.list_external_file",
      "file_storage.create_external_file",
      "file_storage.get_external_file",
      "file_storage.update_external_file",
      "file_storage.delete_external_file",
      "file_storage.list_external_file_collection",
      "file_storage.create_external_file_collection",
      "file_storage.get_external_file_collection",
      "file_storage.update_external_file_collection",
      "file_storage.delete_external_file_collection",

      "inventory.list_stockable",
      "inventory.create_stockable",
      "inventory.get_stockable",
      "inventory.update_stockable",
      "inventory.delete_stockable",
      "inventory.list_unlockable",
      "inventory.create_unlockable",
      "inventory.get_unlockable",
      "inventory.update_unlockable",
      "inventory.delete_unlockable",
      "inventory.list_depositable",
      "inventory.create_depositable",
      "inventory.get_depositable",
      "inventory.update_depositable",
      "inventory.delete_depositable",

      "catalogue.list_product",
      "catalogue.create_product",
      "catalogue.get_product",
      "catalogue.get_product_item",
      "catalogue.list_price",
      "catalogue.get_price",
      "catalogue.list_product_collection",
      "catalogue.get_product_collection"
    ],

    "developer" => [
      "identity.list_account",
      "identity.get_account",
      "identity.get_user",
      "identity.get_refresh_token",

      "file_storage.list_external_file",
      "file_storage.create_external_file",
      "file_storage.get_external_file",
      "file_storage.update_external_file",
      "file_storage.delete_external_file",
      "file_storage.list_external_file_collection",
      "file_storage.create_external_file_collection",
      "file_storage.get_external_file_collection",
      "file_storage.update_external_file_collection",
      "file_storage.delete_external_file_collection",

      "inventory.list_stockable",
      "inventory.create_stockable",
      "inventory.get_stockable",
      "inventory.update_stockable",
      "inventory.delete_stockable",
      "inventory.list_unlockable",
      "inventory.create_unlockable",
      "inventory.get_unlockable",
      "inventory.update_unlockable",
      "inventory.delete_unlockable",
      "inventory.list_depositable",
      "inventory.create_depositable",
      "inventory.get_depositable",
      "inventory.update_depositable",
      "inventory.delete_depositable",

      "catalogue.list_product",
      "catalogue.create_product",
      "catalogue.get_product",
      "catalogue.update_product",
      "catalogue.delete_product",
      "catalogue.list_price",
      "catalogue.create_price",
      "catalogue.get_price",
      "catalogue.update_price",
      "catalogue.delete_price",
      "catalogue.list_product_collection",
      "catalogue.create_product_collection",
      "catalogue.get_product_collection",
      "catalogue.update_product_collection",
      "catalogue.create_product_collection_membership",
      "catalogue.delete_product_collection_membership",

      "crm.list_customer",
      "crm.create_customer",
      "crm.get_customer",
      "crm.update_customer",
      "crm.delete_customer",
      "crm.create_point_transaction",

      "storefront.list_order",
      "storefront.create_order",
      "storefront.get_order",
      "storefront.update_order",
      "storefront.delete_order",
      "storefront.list_order_line_item",
      "storefront.create_order_line_item",
      "storefront.update_order_line_item",
      "storefront.delete_order_line_item",
      "storefront.list_unlock",
      "storefront.get_unlock",

      "billing.list_payment",
      "billing.create_payment",
      "billing.get_payment",
      "billing.update_payment",
      "billing.list_card",
      "billing.update_card",
      "billing.delete_card",
      "billing.create_refund"
    ],

    "administrator" => [
      "identity.list_account",
      "identity.get_account",
      "identity.update_account",
      "identity.create_user",
      "identity.get_user",
      "identity.delete_user",
      "identity.get_refresh_token",

      "file_storage.list_external_file",
      "file_storage.create_external_file",
      "file_storage.get_external_file",
      "file_storage.update_external_file",
      "file_storage.delete_external_file",
      "file_storage.list_external_file_collection",
      "file_storage.create_external_file_collection",
      "file_storage.get_external_file_collection",
      "file_storage.update_external_file_collection",
      "file_storage.delete_external_file_collection",

      "inventory.list_stockable",
      "inventory.create_stockable",
      "inventory.get_stockable",
      "inventory.update_stockable",
      "inventory.delete_stockable",
      "inventory.list_unlockable",
      "inventory.create_unlockable",
      "inventory.get_unlockable",
      "inventory.update_unlockable",
      "inventory.delete_unlockable",
      "inventory.list_depositable",
      "inventory.create_depositable",
      "inventory.get_depositable",
      "inventory.update_depositable",
      "inventory.delete_depositable",

      "catalogue.list_product",
      "catalogue.create_product",
      "catalogue.get_product",
      "catalogue.update_product",
      "catalogue.delete_product",
      "catalogue.list_price",
      "catalogue.create_price",
      "catalogue.get_price",
      "catalogue.update_price",
      "catalogue.delete_price",
      "catalogue.list_product_collection",
      "catalogue.create_product_collection",
      "catalogue.get_product_collection",
      "catalogue.update_product_collection",
      "catalogue.create_product_collection_membership",
      "catalogue.delete_product_collection_membership",

      "crm.list_customer",
      "crm.create_customer",
      "crm.get_customer",
      "crm.update_customer",
      "crm.delete_customer",
      "crm.create_point_transaction",

      "storefront.list_order",
      "storefront.create_order",
      "storefront.get_order",
      "storefront.update_order",
      "storefront.delete_order",
      "storefront.list_order_line_item",
      "storefront.create_order_line_item",
      "storefront.update_order_line_item",
      "storefront.delete_order_line_item",
      "storefront.list_unlock",
      "storefront.get_unlock",

      "billing.list_payment",
      "billing.create_payment",
      "billing.get_payment",
      "billing.update_payment",
      "billing.list_card",
      "billing.update_card",
      "billing.delete_card",
      "billing.get_settings",
      "billing.update_settings",
      "billing.create_refund",

      "data_trading.create_data_import"
    ]
  }

  def authorize(vas, endpoint) when map_size(vas) == 0 do
    authorize("anonymous", endpoint)
  end
  def authorize(%{ user_id: user_id, account_id: account_id }, endpoint) do
    with %AccountMembership{ role: role } <- Repo.get_by(AccountMembership, account_id: account_id, user_id: user_id),
         {:ok, role} <- authorize(role, endpoint)
    do
      {:ok, role}
    else
      nil -> {:error, :no_membership}
      {:error, role} -> {:error, :role_not_allowed}
    end
  end
  def authorize(%{ account_id: account_id }, endpoint) do
    authorize("guest", endpoint)
  end
  def authorize(role, target_endpoint) when is_bitstring(role) do
    endpoints = Map.get(@role_endpoints, role)
    found = Enum.any?(endpoints, fn(endpoint) -> endpoint == target_endpoint end)

    if found do
      {:ok, role}
    else
      {:error, role}
    end
  end

end