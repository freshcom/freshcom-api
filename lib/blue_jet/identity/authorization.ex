defmodule BlueJet.Identity.Authorization do

  alias BlueJet.Repo
  alias BlueJet.Identity.{Account, AccountMembership}

  @testable_endpoints [
    "identity.get_account",
    "identity.update_account",
    "identity.reset_account",
    "identity.get_user",
    "identity.update_user",
    "identity.get_refresh_token",
    "identity.create_password_reset_token",
    "identity.update_password",
    "identity.create_phone_verification_code",
    "identity.create_email_verification_token",
    "identity.create_email_verification",

    "file_storage.list_file",
    "file_storage.create_file",
    "file_storage.get_file",
    "file_storage.update_file",
    "file_storage.delete_file",
    "file_storage.list_file_collection",
    "file_storage.create_file_collection",
    "file_storage.get_file_collection",
    "file_storage.update_file_collection",
    "file_storage.delete_file_collection",
    "file_storage.create_file_collection_membership",
    "file_storage.update_file_collection_membership",
    "file_storage.delete_file_collection_membership",

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
    "catalogue.list_product_collection_membership",
    "catalogue.create_product_collection_membership",
    "catalogue.delete_product_collection_membership",

    "crm.list_customer",
    "crm.create_customer",
    "crm.get_customer",
    "crm.update_customer",
    "crm.delete_customer",
    "crm.list_point_transaction",
    "crm.create_point_transaction",
    "crm.delete_point_transaction",

    "storefront.list_order",
    "storefront.create_order",
    "storefront.get_order",
    "storefront.update_order",
    "storefront.delete_order",
    "storefront.list_order_line_item",
    "storefront.create_order_line_item",
    "storefront.update_order_line_item",
    "storefront.delete_order_line_item",

    "balance.list_payment",
    "balance.create_payment",
    "balance.get_payment",
    "balance.update_payment",
    "balance.delete_payment",
    "balance.list_card",
    "balance.update_card",
    "balance.delete_card",
    "balance.create_refund",
    "balance.get_settings",
    "balance.update_settings",

    "fulfillment.list_fulfillment_package",
    "fulfillment.create_fulfillment_package",
    "fulfillment.show_fulfillment_package",
    "fulfillment.update_fulfillment_package",
    "fulfillment.delete_fulfillment_package",
    "fulfillment.list_fulfillment_item",
    "fulfillment.create_fulfillment_item",
    "fulfillment.show_fulfillment_item",
    "fulfillment.update_fulfillment_item",
    "fulfillment.delete_fulfillment_item",
    "fulfillment.list_return_package",
    "fulfillment.create_return_item",
    "fulfillment.list_unlock",
    "fulfillment.create_unlock",
    "fulfillment.get_unlock",
    "fulfillment.delete_unlock",

    "notification.list_email",
    "notification.list_email_template",
    "notification.create_email_template",
    "notification.get_email_template",
    "notification.update_email_template",
    "notification.delete_email_template",
    "notification.list_sms",
    "notification.list_sms_template",
    "notification.get_sms_template",
    "notification.update_sms_template",
    "notification.delete_sms_template",
    "notification.list_trigger",
    "notification.create_trigger",
    "notification.get_trigger",
    "notification.delete_trigger",

    "data_trading.create_data_import"
  ]

  @role_endpoints %{
    "anonymous" => [
      "identity.create_user",
      "identity.create_password_reset_token",
      "identity.update_password",
      "identity.create_email_verification_token",
      "identity.create_email_verification"
    ],

    "guest" => [
      "identity.create_user",
      "identity.get_account",
      "identity.create_password_reset_token",
      "identity.update_password",
      "identity.create_email_verification_token",
      "identity.create_email_verification",
      "identity.create_phone_verification_code",

      "file_storage.get_file",
      "file_storage.get_file_collection",

      "catalogue.list_product",
      "catalogue.get_product",
      "catalogue.list_product_item",
      "catalogue.get_product_item",
      "catalogue.list_price",
      "catalogue.get_price",
      "catalogue.list_product_collection",
      "catalogue.list_product_collection_membership",

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
      "identity.update_user",
      "identity.delete_user",
      "identity.create_password_reset_token",
      "identity.update_password",
      "identity.create_email_verification_token",
      "identity.create_email_verification",
      "identity.create_phone_verification_code",

      "file_storage.get_file",
      "file_storage.get_file_collection",

      "catalogue.list_product",
      "catalogue.get_product",
      "catalogue.list_product_item",
      "catalogue.get_product_item",
      "catalogue.list_price",
      "catalogue.get_price",
      "catalogue.list_product_collection",
      "catalogue.get_product_collection",
      "catalogue.list_product_collection_membership",

      "crm.get_customer",
      "crm.update_customer",
      "crm.list_point_transaction",
      "crm.create_point_transaction",

      "storefront.list_order",
      "storefront.create_order",
      "storefront.get_order",
      "storefront.update_order",
      "storefront.list_order_line_item",
      "storefront.create_order_line_item",
      "storefront.update_order_line_item",
      "storefront.delete_order_line_item",

      "fulfillment.list_unlock",
      "fulfillment.get_unlock",

      "balance.list_payment",
      "balance.create_payment",
      "balance.get_payment",
      "balance.list_card",
      "balance.update_card",
      "balance.delete_card"
    ],

    "business_analyst" => [
    ],

    "support_specialist" => [
      "identity.list_account",
      "identity.get_account",
      "identity.get_user",
      "identity.update_user",
      "identity.create_password_reset_token",
      "identity.update_password",
      "identity.create_email_verification_token",
      "identity.create_email_verification",

      "file_storage.list_file",
      "file_storage.create_file",
      "file_storage.get_file",
      "file_storage.update_file",
      "file_storage.delete_file",
      "file_storage.list_file_collection",
      "file_storage.create_file_collection",
      "file_storage.get_file_collection",
      "file_storage.update_file_collection",
      "file_storage.delete_file_collection",
      "file_storage.create_file_collection_membership",
      "file_storage.update_file_collection_membership",
      "file_storage.delete_file_collection_membership",

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
      "catalogue.list_product_collection_membership",
      "catalogue.create_product_collection_membership",
      "catalogue.delete_product_collection_membership",

      "crm.list_customer",
      "crm.create_customer",
      "crm.get_customer",
      "crm.update_customer",
      "crm.delete_customer",
      "crm.list_point_transaction",
      "crm.create_point_transaction",
      "crm.get_point_transaction",
      "crm.delete_point_transaction",

      "storefront.list_order",
      "storefront.create_order",
      "storefront.get_order",
      "storefront.update_order",
      "storefront.delete_order",
      "storefront.list_order_line_item",
      "storefront.create_order_line_item",
      "storefront.update_order_line_item",
      "storefront.delete_order_line_item",

      "fulfillment.list_unlock",
      "fulfillment.create_unlock",
      "fulfillment.get_unlock",
      "fulfillment.delete_unlock",

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

    "marketing_specialist" => [
      "identity.create_password_reset_token",
      "identity.update_password",
      "identity.create_email_verification_token",
      "identity.create_email_verification",
      "file_storage.create_file_collection_membership",
      "file_storage.delete_file_collection_membership"
    ],

    "goods_specialist" => [
      "identity.list_account",
      "identity.get_account",
      "identity.get_user",
      "identity.update_user",
      "identity.create_password_reset_token",
      "identity.update_password",
      "identity.create_email_verification_token",
      "identity.create_email_verification",
      "file_storage.create_file_collection_membership",
      "file_storage.update_file_collection_membership",
      "file_storage.delete_file_collection_membership",

      "file_storage.list_file",
      "file_storage.create_file",
      "file_storage.get_file",
      "file_storage.update_file",
      "file_storage.delete_file",
      "file_storage.list_file_collection",
      "file_storage.create_file_collection",
      "file_storage.get_file_collection",
      "file_storage.update_file_collection",
      "file_storage.delete_file_collection",

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
      "catalogue.get_product_collection",
      "catalogue.list_product_collection_membership",

      "fulfillment.list_fulfillment_package",
      "fulfillment.create_fulfillment_package",
      "fulfillment.show_fulfillment_package",
      "fulfillment.update_fulfillment_package",
      "fulfillment.delete_fulfillment_package",
      "fulfillment.list_fulfillment_item",
      "fulfillment.create_fulfillment_item",
      "fulfillment.show_fulfillment_item",
      "fulfillment.update_fulfillment_item",
      "fulfillment.delete_fulfillment_item"
    ],

    "developer" => [
      "identity.list_account",
      "identity.get_account",
      "identity.get_user",
      "identity.update_user",
      "identity.get_refresh_token",
      "identity.create_password_reset_token",
      "identity.update_password",
      "identity.create_email_verification_token",
      "identity.create_email_verification",

      "file_storage.list_file",
      "file_storage.create_file",
      "file_storage.get_file",
      "file_storage.update_file",
      "file_storage.delete_file",
      "file_storage.list_file_collection",
      "file_storage.create_file_collection",
      "file_storage.get_file_collection",
      "file_storage.update_file_collection",
      "file_storage.delete_file_collection",
      "file_storage.create_file_collection_membership",
      "file_storage.update_file_collection_membership",
      "file_storage.delete_file_collection_membership",

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
      "catalogue.list_product_collection_membership",

      "crm.list_customer",
      "crm.create_customer",
      "crm.get_customer",
      "crm.update_customer",
      "crm.delete_customer",
      "crm.list_point_transaction",
      "crm.create_point_transaction",
      "crm.get_point_transaction",
      "crm.delete_point_transaction",

      "storefront.list_order",
      "storefront.create_order",
      "storefront.get_order",
      "storefront.update_order",
      "storefront.delete_order",
      "storefront.list_order_line_item",
      "storefront.create_order_line_item",
      "storefront.update_order_line_item",
      "storefront.delete_order_line_item",

      "balance.list_payment",
      "balance.create_payment",
      "balance.get_payment",
      "balance.update_payment",
      "balance.delete_payment",
      "balance.list_card",
      "balance.update_card",
      "balance.delete_card",
      "balance.create_refund",

      "fulfillment.list_fulfillment_package",
      "fulfillment.create_fulfillment_package",
      "fulfillment.show_fulfillment_package",
      "fulfillment.update_fulfillment_package",
      "fulfillment.delete_fulfillment_package",
      "fulfillment.list_fulfillment_item",
      "fulfillment.create_fulfillment_item",
      "fulfillment.show_fulfillment_item",
      "fulfillment.update_fulfillment_item",
      "fulfillment.delete_fulfillment_item",
      "fulfillment.list_return_package",
      "fulfillment.create_return_item",
      "fulfillment.list_unlock",
      "fulfillment.create_unlock",
      "fulfillment.get_unlock",
      "fulfillment.delete_unlock",

      "notification.list_email",
      "notification.list_email_template",
      "notification.create_email_template",
      "notification.get_email_template",
      "notification.update_email_template",
      "notification.delete_email_template",
      "notification.list_sms",
      "notification.list_sms_template",
      "notification.get_sms_template",
      "notification.update_sms_template",
      "notification.delete_sms_template",
      "notification.list_trigger",
      "notification.create_trigger",
      "notification.get_trigger",
      "notification.delete_trigger"
    ],

    "administrator" => [
      "identity.list_account",
      "identity.get_account",
      "identity.update_account",
      "identity.reset_account",
      "identity.create_user",
      "identity.get_user",
      "identity.update_user",
      "identity.delete_user",
      "identity.get_refresh_token",
      "identity.create_password_reset_token",
      "identity.update_password",
      "identity.create_email_verification_token",
      "identity.create_email_verification",

      "file_storage.list_file",
      "file_storage.create_file",
      "file_storage.get_file",
      "file_storage.update_file",
      "file_storage.delete_file",
      "file_storage.list_file_collection",
      "file_storage.create_file_collection",
      "file_storage.get_file_collection",
      "file_storage.update_file_collection",
      "file_storage.delete_file_collection",
      "file_storage.create_file_collection_membership",
      "file_storage.update_file_collection_membership",
      "file_storage.delete_file_collection_membership",

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
      "catalogue.list_product_collection_membership",

      "crm.list_customer",
      "crm.create_customer",
      "crm.get_customer",
      "crm.update_customer",
      "crm.delete_customer",
      "crm.list_point_transaction",
      "crm.create_point_transaction",
      "crm.get_point_transaction",
      "crm.delete_point_transaction",

      "storefront.list_order",
      "storefront.create_order",
      "storefront.get_order",
      "storefront.update_order",
      "storefront.delete_order",
      "storefront.list_order_line_item",
      "storefront.create_order_line_item",
      "storefront.update_order_line_item",
      "storefront.delete_order_line_item",

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

      "fulfillment.list_fulfillment_package",
      "fulfillment.create_fulfillment_package",
      "fulfillment.show_fulfillment_package",
      "fulfillment.update_fulfillment_package",
      "fulfillment.delete_fulfillment_package",
      "fulfillment.list_fulfillment_item",
      "fulfillment.create_fulfillment_item",
      "fulfillment.show_fulfillment_item",
      "fulfillment.update_fulfillment_item",
      "fulfillment.delete_fulfillment_item",
      "fulfillment.list_return_package",
      "fulfillment.create_return_item",
      "fulfillment.list_unlock",
      "fulfillment.create_unlock",
      "fulfillment.get_unlock",
      "fulfillment.delete_unlock",

      "notification.list_email",
      "notification.list_email_template",
      "notification.create_email_template",
      "notification.get_email_template",
      "notification.update_email_template",
      "notification.delete_email_template",
      "notification.list_sms",
      "notification.list_sms_template",
      "notification.get_sms_template",
      "notification.update_sms_template",
      "notification.delete_sms_template",
      "notification.list_trigger",
      "notification.create_trigger",
      "notification.get_trigger",
      "notification.delete_trigger",

      "data_trading.create_data_import"
    ]
  }

  def authorize_role(role, target_endpoint) when is_bitstring(role) do
    endpoints = Map.get(@role_endpoints, role)
    found = Enum.any?(endpoints, fn(endpoint) -> endpoint == target_endpoint end)

    if found do
      {:ok, role}
    else
      {:error, :role_not_allowed}
    end
  end

  defp authorize_test_account(vas = %{ user_id: user_id }, %{ id: test_account_id, live_account_id: live_account_id }, endpoint) do
    with %AccountMembership{ role: role } <- Repo.get_by(AccountMembership, account_id: test_account_id, user_id: user_id),
         {:ok, role} <- authorize_role(role, endpoint)
    do
      {:ok, role}
    else
      nil ->
        authorize_vas(vas, %{ id: live_account_id, mode: "live" }, endpoint)

      {:error, _} ->
        {:error, :role_not_allowed}
    end
  end

  def authorize_vas(vas, endpoint) when map_size(vas) == 0 do
    case authorize_role("anonymous", endpoint) do
      {:ok, role} ->
        {:ok, %{ role: role, account: nil }}

      other ->
        other
    end
  end

  def authorize_vas(vas = %{ account_id: account_id }, endpoint) do
    account = Repo.get!(Account, account_id)

    case authorize_vas(vas, account, endpoint) do
      {:ok, role} ->
        {:ok, %{ role: role, account: account }}

      other ->
        other
    end
  end

  def authorize_vas(%{ user_id: user_id }, %{ id: account_id, mode: "live" }, endpoint) do
    with %AccountMembership{ role: role } <- Repo.get_by(AccountMembership, account_id: account_id, user_id: user_id),
         {:ok, role} <- authorize_role(role, endpoint)
    do
      {:ok, role}
    else
      nil ->
        {:error, :no_membership}

      {:error, _} ->
        {:error, :role_not_allowed}
    end
  end

  def authorize_vas(vas = %{ user_id: _ }, account = %{ mode: "test" }, endpoint) do
    # Check if the endpoint is testable
    case Enum.find(@testable_endpoints, fn(testable_endpoint) -> endpoint == testable_endpoint end) do
      nil ->
        {:error, :test_account_not_allowed}

      _ ->
        authorize_test_account(vas, account, endpoint)
    end
  end

  def authorize_vas(%{ account_id: _ }, _, endpoint) do
    authorize_role("guest", endpoint)
  end

  def authorize_request(request = %{ vas: vas }, endpoint) do
    with {:ok, %{ role: role, account: account }} <- authorize_vas(vas, endpoint) do
      {:ok, %{ request | role: role, account: account }}
    else
      {:error, _} -> {:error, :access_denied}
    end
  end
end