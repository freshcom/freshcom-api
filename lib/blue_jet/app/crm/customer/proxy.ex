defmodule BlueJet.CRM.Customer.Proxy do
  use BlueJet, :proxy

  alias BlueJet.CRM.{FileStorageService, IdentityService}

  def sync_to_user(customer, opts \\ %{})

  def sync_to_user(%{user_id: nil}, _), do: {:ok, nil}

  def sync_to_user(%{user_id: user_id} = customer, opts) do
    identifiers = %{id: user_id}
    fields =
      Map.take(customer, [
        :email,
        :phone_number,
        :phone_verification_code,
        :name,
        :first_name,
        :last_name
      ])
    opts = %{
      account: get_account(customer),
      bypass_pvc_validation: !!opts[:bypass_user_pvc_validation]
    }

    IdentityService.update_user(identifiers, fields, opts)
  end

  def delete_user(%{user_id: nil}), do: {:ok, nil}

  def delete_user(%{user_id: user_id} = customer) do
    identifiers = %{id: user_id}
    opts = %{account: get_account(customer)}

    IdentityService.delete_user(identifiers, opts)
  end

  def put(customer, {:file_collections, collection_paths}, opts) do
    preload = %{paths: collection_paths, opts: opts}
    opts = Map.put(opts, :preload, preload)
    filter = %{owner_id: customer.id, owner_type: "Customer"}

    collections = FileStorageService.list_file_collection(%{filter: filter}, opts)

    %{customer | file_collections: collections}
  end

  def put(customer, _, _), do: customer
end
