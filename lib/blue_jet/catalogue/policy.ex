defmodule BlueJet.Catalogue.Policy do
  alias BlueJet.AccessRequest
  alias BlueJet.Catalogue.{IdentityService}

  #
  # MARK: Product
  #
  def authorize(request = %{ role: role }, "list_product") when role in ["guest", "customer"] do
    authorized_args = AccessRequest.to_authorized_args(request, :list)

    filter = Map.merge(request.filter, %{ status: "active" })
    all_count_filter = Map.take(filter, [:status, :collection_id, :parent_id])
    authorized_args = %{ authorized_args | filter: filter, all_count_filter: all_count_filter }

    authorized_args = put_in(authorized_args, [:opts, :preloads, :opts, :filters], %{
      prices: %{ status: "active" },
      items: %{ status: "active" },
      variants: %{ status: "active" }
    })

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "list_product") when role in ["support_specialist", "marketing_specialist", "developer", "administrator"] do
    authorized_args = AccessRequest.to_authorized_args(request, :list)

    all_count_filter = Map.take(request.filter, [:collection_id, :parent_id])
    authorized_args = %{ authorized_args | all_count_filter: all_count_filter }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "create_product") when role in ["marketing_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :create)}
  end

  def authorize(request = %{ role: role }, "get_product") when role in ["guest", "customer"] do
    authorized_args = AccessRequest.to_authorized_args(request, :get)

    identifiers = Map.merge(authorized_args.identifiers, %{ status: "active" })
    authorized_args = %{ authorized_args | identifiers: identifiers }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "get_product") when role in ["support_specialist", "marketing_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :get)}
  end

  def authorize(request = %{ role: role }, "update_product") when role in ["marketing_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :update)}
  end

  def authorize(request = %{ role: role }, "delete_product") when role in ["marketing_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :delete)}
  end

  #
  # MARK: Product Collection
  #
  def authorize(request = %{ role: role }, "list_product_collection") when role in ["guest", "customer"] do
    authorized_args = AccessRequest.to_authorized_args(request, :list)

    filter = Map.merge(request.filter, %{ status: "active" })
    all_count_filter = Map.take(filter, [:status])
    authorized_args = %{ authorized_args | filter: filter, all_count_filter: all_count_filter }

    authorized_args = put_in(authorized_args, [:opts, :preloads, :opts, :filters], %{
      memberships: %{ product_status: "active" }
    })

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "list_product_collection") when role in ["support_specialist", "marketing_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :list)}
  end

  #
  # MARK: Other
  #
  def authorize(request = %{ role: nil }, endpoint) do
    request
    |> IdentityService.put_vas_data()
    |> authorize(endpoint)
  end

  def authorize(_, _) do
    {:error, :access_denied}
  end
end
