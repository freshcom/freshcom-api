defmodule BlueJet.FileStorage.Policy do
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
  # MARK: File
  #
  def authorize(%{_role_: role} = req, :list_file)
      when role in ["developer", "administrator"] do
    req = ContextRequest.put(req, :filter, :status, "uploaded")
    req =
      req
      |> ContextRequest.put(:_scope_, Map.take(req.filter, [:status]))
      |> ContextRequest.put(:_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: _}, :list_file), do: {:error, :access_denied}

  def authorize(%{_role_: "anonymous"}, :create_file), do: {:error, :access_denied}

  def authorize(%{_role_: "guest"} = req, :create_file) do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :create_file) when not is_nil(role) do
    req =
      req
      |> ContextRequest.put(:fields, "user_id", req._vad_[:user].id)
      |> ContextRequest.put(:_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: "anonymous"}, :get_file), do: {:error, :access_denied}

  def authorize(%{_role_: role} = req, :get_file) when not is_nil(role) do
    req =
      req
      |> ContextRequest.put(:identifiers, :status, "uploaded")
      |> ContextRequest.put(:_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: "anonymous"}, :update_file), do: {:error, :access_denied}

  def authorize(%{_role_: role} = req, :update_file) when role in ["guest", "customer"] do
    req =
      req
      |> ContextRequest.put(:fields, Map.take(req.fields, [:status]))
      |> ContextRequest.put(:_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :update_file) when not is_nil(role) do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role}, :delete_file) when role in ["anonymous", "guest"], do: {:error, :access_denied}

  def authorize(%{_role_: role} = req, :delete_file)
      when role in ["developer", "administrator"] do
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :delete_file)
      when not is_nil(role) do
    req = ContextRequest.put(req, :identifiers, :user_id, req._vad_[:user].id)

    {:ok, req}
  end

  #
  # File Collection
  #
  def authorize(%{role: "anonymous"}, :list_file_collection), do: {:error, :access_denied}

  # Guest and customer can only list active file collection for a specific owner
  def authorize(%{_role_: role} = req, :list_file_collection)
      when role in ["guest", "customer"] do
    if req.filter[:owner_id] && req.filter[:owner_id] do
      req =
        req
        |> ContextRequest.put(:filter, :status, "active")
        |> ContextRequest.put(:_scope_, Map.take(req.filter, [:status, :owner_id, :owner_type]))
        |> ContextRequest.put(:_include_, :paths, req.include)

      {:ok, req}
    else
      {:error, :access_denied}
    end
  end

  # Developer and adminstrator can list all file collection
  def authorize(%{_role_: role} = req, :list_file_collection)
      when role in ["developer", "administrator"] do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  # Other role can only list file collection for a specific owner
  def authorize(%{_role_: role} = req, :list_file_collection) when not is_nil(role) do
    if req.filter[:owner_id] && req.filter[:owner_id] do
      req =
        req
        |> ContextRequest.put(:_scope_, Map.take(req.filter, [:owner_id, :owner_type]))
        |> ContextRequest.put(:_include_, :paths, req.include)

      {:ok, req}
    else
      {:error, :access_denied}
    end
  end

  def authorize(%{_role_: role}, :create_file_collection) when role in ["anonymous", "guest", "customer"],
      do: {:error, :access_denied}

  def authorize(%{_role_: role} = req, :create_file_collection) when not is_nil(role) do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{role: "anonymous"}, :get_file_collection), do: {:error, :access_denied}

  def authorize(%{_role_: role} = req, :get_file_collection)
      when role in ["guest", "customer"] do
    req =
      req
      |> ContextRequest.put(:identifiers, :status, "active")
      |> ContextRequest.put(:_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :get_file_collection) when not is_nil(role) do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role}, :update_file_collection) when role in ["anonymous", "guest", "customer"],
    do: {:error, :access_denied}

  def authorize(%{_role_: role} = req, :update_file_collection) when not is_nil(role) do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role}, :delete_file_collection) when role in ["anonymous", "guest", "customer"],
    do: {:error, :access_denied}

  def authorize(%{_role_: role} = req, :delete_file_collection) when not is_nil(role) do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  #
  # MARK: File Collection Membership
  #
  def authorize(%{_role_: "anonymous"}, :list_file_collection_membership), do: {:error, :access_denied}

  def authorize(%{_role_: role} = req, :list_file_collection_membership) when role in ["guest", "customer"] do
    req = ContextRequest.put(req, :filter, :file_status, "uploaded")
    req =
      req
      |> ContextRequest.put(:_scope_, Map.take(req.filter, [:collection_id, :file_status]))
      |> ContextRequest.put(:_include_, :paths, req.include)
      |> ContextRequest.put(:_include_, :opts, %{filters: %{file: %{status: "uploaded"}}})

    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :list_file_collection_membership) when not is_nil(role) do
    req =
      req
      |> ContextRequest.put(:_scope_, Map.take(req.filter, [:collection_id]))
      |> ContextRequest.put(:_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role}, :create_file_collection_membership)
      when role in ["anonymous", "guest", "customer"],
      do: {:error, :access_denied}

  def authorize(%{_role_: role} = req, :create_file_collection_membership)
      when not is_nil(role) do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role}, :get_file_collection_membership)
      when role in ["anonymous", "guest", "customer"],
      do: {:error, :access_denied}

  def authorize(%{_role_: role} = req, :get_file_collection_membership) when not is_nil(role) do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role}, :update_file_collection_membership)
      when role in ["anonymous", "guest", "customer"],
      do: {:error, :access_denied}

  def authorize(%{_role_: role} = req, :update_file_collection_membership)
      when not is_nil(role) do
    req = ContextRequest.put(req, :_include_, :paths, req.include)

    {:ok, req}
  end

  def authorize(%{_role_: role}, :delete_file_collection_membership)
      when role in ["anonymous", "guest", "customer"],
      do: {:error, :access_denied}

  def authorize(%{_role_: role} = req, :delete_file_collection_membership)
      when not is_nil(role) do
    {:ok, req}
  end

  #
  # MARK: Other
  #
  def authorize(_, _) do
    {:error, :access_denied}
  end
end
