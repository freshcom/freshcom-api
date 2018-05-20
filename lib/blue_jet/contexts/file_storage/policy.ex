defmodule BlueJet.FileStorage.Policy do
  use BlueJet, :policy

  alias BlueJet.FileStorage.Service

  #
  # MARK: File
  #
  def authorize(%{ role: "anonymous" }, "list_file"), do: {:error, :access_denied}

  def authorize(request = %{ role: role }, "list_file") when role in ["developer", "administrator"] do
    authorized_args = from_access_request(request, :list)
    filter = Map.merge(authorized_args[:filter], %{ status: "uploaded" })
    all_count_filter = Map.take(filter, [:status])
    authorized_args = %{ authorized_args | filter: filter, all_count_filter: all_count_filter }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "list_file") when not is_nil(role) do
    authorized_args = from_access_request(request, :list)

    if authorized_args[:filter][:collection_id] do
      filter = Map.merge(authorized_args[:filter], %{ status: "uploaded" })
      all_count_filter = Map.take(filter, [:status, :collection_id])
      authorized_args = %{ authorized_args | filter: filter, all_count_filter: all_count_filter }

      {:ok, authorized_args}
    else
      {:error, :access_denied}
    end
  end

  def authorize(%{ role: "anonymous" }, "create_file"), do: {:error, :access_denied}

  def authorize(request = %{ user: user, role: role }, "create_file") when not is_nil(role) do
    authorized_args = from_access_request(request, :create)
    fields = if user do
      Map.merge(authorized_args[:fields], %{ "user_id" => user.id })
    else
      authorized_args[:fields]
    end

    authorized_args = %{ authorized_args | fields: fields }

    {:ok, authorized_args}
  end

  def authorize(%{ role: "anonymous" }, "get_file"), do: {:error, :access_denied}

  def authorize(request = %{ role: role }, "get_file") when not is_nil(role) do
    authorized_args = from_access_request(request, :get)

    identifiers = Map.merge(authorized_args[:identifiers], %{ status: "uploaded" })
    authorized_args = %{ authorized_args | identifiers: identifiers }

    {:ok, authorized_args}
  end

  def authorize(%{ role: "anonymous" }, "update_file"), do: {:error, :access_denied}

  def authorize(request = %{ role: role }, "update_file") when role in ["guest", "customer"] do
    authorized_args = from_access_request(request, :update)

    fields = Map.take(authorized_args, [:status])
    authorized_args = %{ authorized_args | fields: fields }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "update_file") when not is_nil(role) do
    {:ok, from_access_request(request, :update)}
  end

  def authorize(%{ role: role }, "delete_file") when role in ["anonymous", "guest"], do: {:error, :access_denied}

  def authorize(request = %{ role: role }, "delete_file") when role in ["developer", "administrator"] do
    {:ok, from_access_request(request, :delete)}
  end

  def authorize(request = %{ account: account, user: user, role: role }, "delete_file") when not is_nil(role) do
    authorized_args = from_access_request(request, :delete)

    file = Service.get_file(%{ id: authorized_args[:id], user_id: user.id }, %{ account: account })
    if file do
      {:ok, authorized_args}
    else
      {:error, :access_denied}
    end
  end

  #
  # File Collection
  #
  def authorize(%{ role: "anonymous" }, "list_file_collection"), do: {:error, :access_denied}

  # Guest and customer can only list active file collection for a specific owner
  def authorize(request = %{ role: role }, "list_file_collection") when role in ["guest", "customer"] do
    authorized_args = from_access_request(request, :list)

    if authorized_args[:filter][:owner_id] && authorized_args[:filter][:owner_type] do
      filter = Map.merge(authorized_args[:filter], %{ status: "active" })
      all_count_filter = Map.take(filter, [:status, :owner_id, :owner_type])
      authorized_args = %{ authorized_args | filter: filter, all_count_filter: all_count_filter }

      {:ok, authorized_args}
    else
      {:error, :access_denied}
    end
  end

  # Developer and adminstrator can list all file collection
  def authorize(request = %{ role: role }, "list_file_collection") when role in ["developer", "administrator"] do
    {:ok, from_access_request(request, :list)}
  end

  # Other role can only list file collection for a specific owner
  def authorize(request = %{ role: role }, "list_file_collection") when not is_nil(role) do
    authorized_args = from_access_request(request, :list)

    if authorized_args[:filter][:owner_id] && authorized_args[:filter][:owner_type] do
      all_count_filter = Map.take(authorized_args[:filter], [:owner_id, :owner_type])
      authorized_args = %{ authorized_args | all_count_filter: all_count_filter }

      {:ok, authorized_args}
    else
      {:error, :access_denied}
    end
  end

  def authorize(%{ role: role }, "create_file_collection") when role in ["anonymous", "guest", "customer"], do: {:error, :access_denied}

  def authorize(request = %{ role: role }, "create_file_collection") when not is_nil(role) do
    {:ok, from_access_request(request, :create)}
  end

  def authorize(%{ role: "anonymous" }, "get_file_collection"), do: {:error, :access_denied}

  def authorize(request = %{ role: role }, "get_file_collection") when role in ["guest", "customer"] do
    authorized_args = from_access_request(request, :get)

    identifiers = Map.merge(authorized_args[:identifiers], %{ status: "active" })
    authorized_args = %{ authorized_args | identifiers: identifiers }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "get_file_collection") when not is_nil(role) do
    {:ok, from_access_request(request, :get)}
  end

  def authorize(%{ role: role }, "update_file_collection") when role in ["anonymous", "guest", "customer"], do: {:error, :access_denied}

  def authorize(request = %{ role: role }, "update_file_collection") when not is_nil(role) do
    {:ok, from_access_request(request, :update)}
  end

  def authorize(%{ role: role }, "delete_file_collection") when role in ["anonymous", "guest", "customer"], do: {:error, :access_denied}

  def authorize(request = %{ role: role }, "delete_file_collection") when not is_nil(role) do
    {:ok, from_access_request(request, :delete)}
  end

  #
  # MARK: File Collection Membership
  #
  def authorize(%{ role: role }, "create_file_collection_membership") when role in ["anonymous", "guest", "customer"], do: {:error, :access_denied}

  def authorize(request = %{ role: role }, "create_file_collection_membership") when not is_nil(role) do
    authorized_args = from_access_request(request, :create)

    fields = Map.merge(authorized_args[:fields], Map.take(request.params, ["collection_id", "file_id"]))
    authorized_args = %{ authorized_args | fields: fields }

    {:ok, authorized_args}
  end

  def authorize(%{ role: role }, "update_file_collection_membership") when role in ["anonymous", "guest", "customer"], do: {:error, :access_denied}

  def authorize(request = %{ role: role }, "update_file_collection_membership") when not is_nil(role) do
    {:ok, from_access_request(request, :update)}
  end

  def authorize(%{ role: role }, "delete_file_collection_membership") when role in ["anonymous", "guest", "customer"], do: {:error, :access_denied}

  def authorize(request = %{ role: role }, "delete_file_collection_membership") when not is_nil(role) do
    {:ok, from_access_request(request, :delete)}
  end

  #
  # MARK: Other
  #
  def authorize(_, _) do
    {:error, :access_denied}
  end
end
