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

      "storefront.create_order",
      "storefront.get_order",
      "storefront.update_order",
      "storefront.create_customer",

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

      "file_storage.get_external_file",
      "file_storage.get_external_file_collection",
      "catalogue.get_product",
      "catalogue.list_product_item",
      "catalogue.get_product_item",
      "catalogue.list_price",
      "catalogue.get_price",

      "storefront.list_order",
      "storefront.create_order",
      "storefront.get_order",
      "storefront.update_order",

      "billing.list_payment",
      "billing.create_payment",
      "billing.get_payment",
      "billing.list_card",

      "storefront.create_order_line_item",
      "storefront.update_order_line_item",
      "storefront.delete_order_line_item"
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

      "identity.list_sku",
      "identity.get_sku",

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

      "storefront.list_order",
      "storefront.create_order",
      "storefront.get_order",
      "storefront.update_order",
      "storefront.delete_order",
      "storefront.create_customer",

      "billing.list_payment",
      "billing.create_payment",
      "billing.get_payment",
      "billing.update_payment",
      "billing.list_card",
      "billing.create_refund",

      "storefront.create_order_line_item",
      "storefront.update_order_line_item",
      "storefront.delete_order_line_item"
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

      "inventory.list_sku",
      "inventory.create_sku",
      "inventory.get_sku",
      "inventory.update_sku",
      "inventory.delete_sku",
      "inventory.list_unlockable",
      "inventory.create_unlockable",
      "inventory.get_unlockable",
      "inventory.update_unlockable",
      "inventory.delete_unlockable",

      "catalogue.list_product",
      "catalogue.create_product",
      "catalogue.get_product",
      "catalogue.get_product_item",
      "catalogue.list_price",
      "catalogue.get_price"
    ],

    "developer" => [
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

      "inventory.list_sku",
      "inventory.create_sku",
      "inventory.get_sku",
      "inventory.update_sku",
      "inventory.delete_sku",
      "inventory.list_unlockable",
      "inventory.create_unlockable",
      "inventory.get_unlockable",
      "inventory.update_unlockable",
      "inventory.delete_unlockable",

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

      "storefront.list_order",
      "storefront.create_order",
      "storefront.get_order",
      "storefront.update_order",
      "storefront.delete_order",
      "storefront.create_customer",

      "billing.list_payment",
      "billing.create_payment",
      "billing.get_payment",
      "billing.update_payment",
      "billing.list_card",
      "billing.create_refund",

      "storefront.create_order_line_item",
      "storefront.update_order_line_item",
      "storefront.delete_order_line_item"
    ],

    "administrator" => [
      "identity.list_account",
      "identity.get_account",
      "identity.update_account",
      "identity.create_user",
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

      "inventory.list_sku",
      "inventory.create_sku",
      "inventory.get_sku",
      "inventory.update_sku",
      "inventory.delete_sku",
      "inventory.list_unlockable",
      "inventory.create_unlockable",
      "inventory.get_unlockable",
      "inventory.update_unlockable",
      "inventory.delete_unlockable",

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

      "storefront.list_order",
      "storefront.create_order",
      "storefront.get_order",
      "storefront.update_order",
      "storefront.delete_order",
      "storefront.create_customer",

      "billing.list_payment",
      "billing.create_payment",
      "billing.get_payment",
      "billing.update_payment",
      "billing.list_card",
      "billing.get_settings",
      "billing.update_settings",
      "billing.create_refund",

      "storefront.create_order_line_item",
      "storefront.update_order_line_item",
      "storefront.delete_order_line_item"
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