defmodule BlueJet.Catalogue.Policy do
  use BlueJet, :policy

  # TODO: Fix this
  def authorize(%{vas: vas, _role_: nil} = req, endpoint) do
    identity_service =
      Atom.to_string(__MODULE__)
      |> String.split(".")
      |> Enum.drop(-1)
      |> Enum.join(".")
      |> Module.concat(IdentityService)

    vad = identity_service.get_vad(vas)
    role = identity_service.get_role(vad)
    default_locale = if vad[:account], do: vad[:account].default_locale, else: nil

    req
    |> Map.put(:_vad_, vad)
    |> Map.put(:_role_, role)
    |> Map.put(:_default_locale_, default_locale)
    |> authorize(endpoint)
  end

  #
  # MARK: Product
  #
  def authorize(%{_role_: role} = req, :list_product) when role in ["guest", "customer"] do
    req = ContextRequest.put(req, :filter, "status", "active")
    scope = Map.take(req.filter, ["status", "collection_id", "parent_id"])

    req =
      req
      |> ContextRequest.put(:_scope_, scope)
      |> ContextRequest.put(:_include_, :paths, req.include)
      |> ContextRequest.put(:_include_, :opts, %{
        filters: %{
          prices: %{status: "active"},
          items: %{status: "active"},
          variants: %{status: "active"}
        }
      })

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :list_product)
      when role in ["support_specialist", "marketing_specialist", "developer", "administrator"] do
    scope = Map.take(req.filter, ["collection_id", "parent_id"])
    req =
      req
      |> ContextRequest.put(:_scope_, scope)
      |> ContextRequest.put(:_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :create_product)
      when role in ["marketing_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :get_product) when role in ["guest", "customer"] do
    req =
      req
      |> ContextRequest.put(:identifiers, "status", "active")
      |> ContextRequest.put(:_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :get_product)
      when role in ["support_specialist", "marketing_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :update_product)
      when role in ["marketing_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :delete_product)
      when role in ["marketing_specialist", "developer", "administrator"] do
    {:ok, req}
  end

  #
  # MARK: Price
  #
  def authorize(%{_role_: role} = req, :list_price) when role in ["guest", "customer"] do
    req = ContextRequest.put(req, :filter, "status", "active")
    req =
      req
      |> ContextRequest.put(:_scope_, Map.take(req.filter, ["product_id", "status"]))
      |> ContextRequest.put(:_include_, :paths, req.include)
      |> ContextRequest.put(:_include_, :opts, %{filters: %{product: %{status: "active"}}})

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :list_price)
      when role in ["support_specialist", "marketing_specialist", "developer", "administrator"] do
    req =
      req
      |> ContextRequest.put(:_scope_, Map.take(req.filter, ["product_id"]))
      |> ContextRequest.put(:_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :create_price)
      when role in ["marketing_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :get_price) when role in ["guest", "customer"] do
    req =
      req
      |> ContextRequest.put(:identifiers, "status", "active")
      |> ContextRequest.put(:_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :get_price)
      when role in ["marketing_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :update_price)
      when role in ["support_specialist", "marketing_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :delete_price)
      when role in ["marketing_specialist", "developer", "administrator"] do
    {:ok, req}
  end

  #
  # MARK: Product Collection
  #
  def authorize(%{_role_: role} = req, :list_product_collection)
      when role in ["guest", "customer"] do
    req = ContextRequest.put(req, :filter, "status", "active")
    req =
      req
      |> ContextRequest.put(:_scope_, Map.take(req.filter, ["status"]))
      |> ContextRequest.put(:_include_, :paths, req.include)
      |> ContextRequest.put(:_include_, :opts, %{filters: %{memberships: %{product_status: "active"}}})

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :list_product_collection)
      when role in ["support_specialist", "marketing_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :create_product_collection)
      when role in ["marketing_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :get_product_collection)
      when role in ["guest", "customer"] do
    req =
      req
      |> ContextRequest.put(:identifiers, "status", "active")
      |> ContextRequest.put(:_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :get_product_collection)
      when role in ["support_specialist", "marketing_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :update_product_collection)
      when role in ["marketing_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :delete_product_collection)
      when role in ["marketing_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  #
  # MARK: Product Collection Membership
  #
  def authorize(%{_role_: role} = req, :list_product_collection_membership)
      when role in ["guest", "customer"] do
    req = ContextRequest.put(req, :filter, "product_status", "active")
    req =
      req
      |> ContextRequest.put(:_scope_, Map.take(req.filter, ["collection_id", "product_status"]))
      |> ContextRequest.put(:_include_, :paths, req.include)
      |> ContextRequest.put(:_include_, :opts, %{filters: %{product: %{status: "active"}}})

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :list_product_collection_membership)
      when role in ["support_specialist", "marketing_specialist", "developer", "administrator"] do
    req =
      req
      |> ContextRequest.put(:_scope_, Map.take(req.filter, ["collection_id"]))
      |> ContextRequest.put(:_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :create_product_collection_membership)
      when role in ["marketing_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :get_product_collection_membership)
      when role in ["marketing_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :update_product_collection_membership)
      when role in ["marketing_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :delete_product_collection_membership)
      when role in ["marketing_specialist", "developer", "administrator"] do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  #
  # MARK: Other
  #
  def authorize(_, _) do
    {:error, :access_denied}
  end
end
