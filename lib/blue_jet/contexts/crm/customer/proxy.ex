defmodule BlueJet.Crm.Customer.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Crm.FileStorageService

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