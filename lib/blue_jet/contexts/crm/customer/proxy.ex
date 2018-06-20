defmodule BlueJet.Crm.Customer.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Crm.{FileStorageService, IdentityService}

  def sync_to_user(customer, opts \\ %{}) do
    account = get_account(customer)
    fields = Map.take(customer, [:email, :phone_number, :phone_verification_code, :name, :first_name, :last_name])

    IdentityService.update_user(customer.user_id, fields, %{ account: account, bypass_pvc_validation: !!opts[:bypass_user_pvc_validation] })
  end

  def put(customer, {:file_collections, file_collection_path}, opts) do
    preloads = %{ path: file_collection_path, opts: opts }
    opts =
      opts
      |> Map.take([:account, :account_id])
      |> Map.merge(%{ preloads: preloads })

    file_collections = FileStorageService.list_file_collection(%{ filter: %{ owner_id: customer.id, owner_type: "Customer" } }, opts)
    %{ customer | file_collections: file_collections }
  end

  def put(customer, _, _), do: customer
end