defmodule BlueJet.Catalogue.Policy do
  use BlueJet, :policy

  #
  # MARK: Product
  #
  def authorize(request = %{ role: role }, "list_product") when role in ["guest", "customer"] do
    authorized_args = from_access_request(request, :list)

    filter = Map.merge(authorized_args[:filter], %{ status: "active" })
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
    authorized_args = from_access_request(request, :list)

    all_count_filter = Map.take(authorized_args[:filter], [:collection_id, :parent_id])
    authorized_args = %{ authorized_args | all_count_filter: all_count_filter }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "create_product") when role in ["marketing_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :create)}
  end

  def authorize(request = %{ role: role }, "get_product") when role in ["guest", "customer"] do
    authorized_args = from_access_request(request, :get)

    identifiers = Map.merge(authorized_args.identifiers, %{ status: "active" })
    authorized_args = %{ authorized_args | identifiers: identifiers }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "get_product") when role in ["support_specialist", "marketing_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :get)}
  end

  def authorize(request = %{ role: role }, "update_product") when role in ["marketing_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :update)}
  end

  def authorize(request = %{ role: role }, "delete_product") when role in ["marketing_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :delete)}
  end

  #
  # MARK: Product Collection
  #
  def authorize(request = %{ role: role }, "list_product_collection") when role in ["guest", "customer"] do
    authorized_args = from_access_request(request, :list)

    filter = Map.merge(authorized_args[:filter], %{ status: "active" })
    all_count_filter = Map.take(filter, [:status])
    authorized_args = %{ authorized_args | filter: filter, all_count_filter: all_count_filter }

    authorized_args = put_in(authorized_args, [:opts, :preloads, :opts, :filters], %{
      memberships: %{ product_status: "active" }
    })

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "list_product_collection") when role in ["support_specialist", "marketing_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :list)}
  end

  def authorize(request = %{ role: role }, "create_product_collection") when role in ["marketing_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :create)}
  end

  def authorize(request = %{ role: role }, "get_product_collection") when role in ["guest", "customer"] do
    authorized_args = from_access_request(request, :get)

    identifiers = Map.merge(authorized_args.identifiers, %{ status: "active" })
    authorized_args = %{ authorized_args | identifiers: identifiers }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "get_product_collection") when role in ["support_specialist", "marketing_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :get)}
  end

  def authorize(request = %{ role: role }, "update_product_collection") when role in ["marketing_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :update)}
  end

  def authorize(request = %{ role: role }, "delete_product_collection") when role in ["marketing_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :delete)}
  end

  #
  # MARK: Product Collection Membership
  #
  def authorize(request = %{ role: role }, "list_product_collection_membership") when role in ["guest", "customer"] do
    authorized_args = from_access_request(request, :list)

    filter = Map.merge(authorized_args[:filter], %{ collection_id: request.params["collection_id"], product_status: "active" })
    all_count_filter = Map.take(filter, [:collection_id, :product_status])
    authorized_args = %{ authorized_args | filter: filter, all_count_filter: all_count_filter }

    authorized_args = put_in(authorized_args, [:opts, :preloads, :opts, :filters], %{
      product: %{ status: "active" }
    })

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "list_product_collection_membership") when role in ["support_specialist", "marketing_specialist", "developer", "administrator"] do
    authorized_args = from_access_request(request, :list)

    filter = Map.merge(authorized_args[:filter], %{ collection_id: request.params["collection_id"] })
    all_count_filter = Map.take(filter, [:collection_id])
    authorized_args = %{ authorized_args | filter: filter, all_count_filter: all_count_filter }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "create_product_collection_membership") when role in ["marketing_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :create)}
  end

  def authorize(request = %{ role: role }, "delete_product_collection_membership") when role in ["marketing_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :delete)}
  end

  #
  # MARK: Price
  #
  def authorize(request = %{ role: role }, "list_price") when role in ["guest", "customer"] do
    authorized_args = from_access_request(request, :list)

    filter = Map.merge(authorized_args[:filter], %{ product_id: request.params["product_id"], status: "active" })
    all_count_filter = Map.take(filter, [:product_id, :status])
    authorized_args = %{ authorized_args | filter: filter, all_count_filter: all_count_filter }

    authorized_args = put_in(authorized_args, [:opts, :preloads, :opts, :filters], %{
      product: %{ status: "active" }
    })

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "list_price") when role in ["support_specialist", "marketing_specialist", "developer", "administrator"] do
    authorized_args = from_access_request(request, :list)

    filter = Map.merge(authorized_args[:filter], %{ product_id: request.params["product_id"] })
    all_count_filter = Map.take(filter, [:product_id])
    authorized_args = %{ authorized_args | filter: filter, all_count_filter: all_count_filter }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "create_price") when role in ["marketing_specialist", "developer", "administrator"] do
    authorized_args = from_access_request(request, :create)

    fields = Map.merge(authorized_args[:fields], %{ "product_id" => request.params["product_id"] })
    authorized_args = %{ authorized_args | fields: fields }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "get_price") when role in ["guest", "customer"] do
    authorized_args = from_access_request(request, :get)

    identifiers = Map.merge(authorized_args.identifiers, %{ status: "active" })
    authorized_args = %{ authorized_args | identifiers: identifiers }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "get_price") when role in ["marketing_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :get)}
  end

  def authorize(request = %{ role: role }, "update_price") when role in ["support_specialist", "marketing_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :update)}
  end

  def authorize(request = %{ role: role }, "delete_price") when role in ["marketing_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :delete)}
  end

  #
  # MARK: Other
  #
  def authorize(_, _) do
    {:error, :access_denied}
  end
end
