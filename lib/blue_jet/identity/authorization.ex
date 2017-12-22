defmodule BlueJet.Identity.Authorization do

  alias BlueJet.Identity.AccountMembership
  alias BlueJet.Identity.Account
  alias BlueJet.Repo

  @testable_endpoints [
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

    "goods.list_stockable",
    "goods.create_stockable",
    "goods.get_stockable",
    "goods.update_stockable",
    "goods.delete_stockable",
    "goods.list_unlockable",
    "goods.create_unlockable",
    "goods.get_unlockable",
    "goods.update_unlockable",
    "goods.delete_unlockable",
    "goods.list_depositable",
    "goods.create_depositable",
    "goods.get_depositable",
    "goods.update_depositable",
    "goods.delete_depositable",

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

    "balance.list_payment",
    "balance.create_payment",
    "balance.get_payment",
    "balance.update_payment",
    "balance.list_card",
    "balance.update_card",
    "balance.delete_card",
    "balance.create_refund",

    "data_trading.create_data_import"
  ]

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

      "balance.create_payment",
      "balance.get_payment",

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

      "balance.list_payment",
      "balance.create_payment",
      "balance.get_payment",
      "balance.list_card",
      "balance.update_card",
      "balance.delete_card"
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
      "crm.get_point_transaction",

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

      "balance.list_payment",
      "balance.create_payment",
      "balance.get_payment",
      "balance.update_payment",
      "balance.delete_payment",
      "balance.list_card",
      "balance.update_card",
      "balance.delete_card",
      "balance.create_refund"
    ],

    "goods_specialist" => [
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

      "goods.list_stockable",
      "goods.create_stockable",
      "goods.get_stockable",
      "goods.update_stockable",
      "goods.delete_stockable",
      "goods.list_unlockable",
      "goods.create_unlockable",
      "goods.get_unlockable",
      "goods.update_unlockable",
      "goods.delete_unlockable",
      "goods.list_depositable",
      "goods.create_depositable",
      "goods.get_depositable",
      "goods.update_depositable",
      "goods.delete_depositable",

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

      "goods.list_stockable",
      "goods.create_stockable",
      "goods.get_stockable",
      "goods.update_stockable",
      "goods.delete_stockable",
      "goods.list_unlockable",
      "goods.create_unlockable",
      "goods.get_unlockable",
      "goods.update_unlockable",
      "goods.delete_unlockable",
      "goods.list_depositable",
      "goods.create_depositable",
      "goods.get_depositable",
      "goods.update_depositable",
      "goods.delete_depositable",

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
      "crm.get_point_transaction",

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

      "balance.list_payment",
      "balance.create_payment",
      "balance.get_payment",
      "balance.update_payment",
      "balance.delete_payment",
      "balance.list_card",
      "balance.update_card",
      "balance.delete_card",
      "balance.create_refund"
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

      "goods.list_stockable",
      "goods.create_stockable",
      "goods.get_stockable",
      "goods.update_stockable",
      "goods.delete_stockable",
      "goods.list_unlockable",
      "goods.create_unlockable",
      "goods.get_unlockable",
      "goods.update_unlockable",
      "goods.delete_unlockable",
      "goods.list_depositable",
      "goods.create_depositable",
      "goods.get_depositable",
      "goods.update_depositable",
      "goods.delete_depositable",

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
      "crm.get_point_transaction",

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

      "balance.list_payment",
      "balance.create_payment",
      "balance.get_payment",
      "balance.update_payment",
      "balance.delete_payment",
      "balance.list_card",
      "balance.update_card",
      "balance.delete_card",
      "balance.get_settings",
      "balance.update_settings",
      "balance.create_refund",

      "data_trading.create_data_import"
    ]
  }

  def authorize(vas, endpoint) when map_size(vas) == 0 do
    case authorize("anonymous", endpoint) do
      {:ok, role} -> {:ok, %{ role: role, account: nil }}
      other -> other
    end
  end

  def authorize(vas = %{ account_id: account_id }, endpoint) do
    account = Repo.get!(Account, account_id)
    case authorize(vas, account, endpoint) do
      {:ok, role} -> {:ok, %{ role: role, account: account }}
      other -> other
    end
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

  def authorize(%{ user_id: user_id }, %{ id: account_id, mode: "live" }, endpoint) do
    with %AccountMembership{ role: role } <- Repo.get_by(AccountMembership, account_id: account_id, user_id: user_id),
         {:ok, role} <- authorize(role, endpoint)
    do
      {:ok, role}
    else
      nil -> {:error, :no_membership}
      {:error, _} -> {:error, :role_not_allowed}
    end
  end

  def authorize(vas = %{ user_id: _ }, account = %{ mode: "test" }, endpoint) do
    # Check if the endpoint is testable
    case Enum.find(@testable_endpoints, fn(testable_endpoint) -> endpoint == testable_endpoint end) do
      nil -> {:error, :test_account_not_allowed}
      _ -> authorize_test_account(vas, account, endpoint)
    end
  end

  def authorize(%{ account_id: _ }, _, endpoint) do
    authorize("guest", endpoint)
  end

  defp authorize_test_account(vas = %{ user_id: user_id }, %{ id: test_account_id, live_account_id: live_account_id }, endpoint) do
    with %AccountMembership{ role: role } <- Repo.get_by(AccountMembership, account_id: test_account_id, user_id: user_id),
         {:ok, role} <- authorize(role, endpoint)
    do
      {:ok, role}
    else
      nil -> authorize(vas, %{ id: live_account_id, mode: "live" }, endpoint)
      {:error, _} -> {:error, :role_not_allowed}
    end
  end
end