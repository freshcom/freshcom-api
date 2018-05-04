defmodule BlueJet.FileStorage.Policy do
  alias BlueJet.AccessRequest
  alias BlueJet.FileStorage.{IdentityService}
  alias BlueJet.FileStorage.Service
  #
  # MARK: File
  #
  def authorize(request = %{ role: "anonymous" }, "list_file"), do: {:error, :access_denied}

  def authorize(request = %{ role: role }, "list_file") when role in ["developer", "administrator"] do
    authorized_args = AccessRequest.to_authorized_args(request, :list)
    filter = Map.merge(authorized_args[:filter], %{ status: "uploaded" })
    all_count_filter = Map.take(filter, [:status])
    authorized_args = %{ authorized_args | filter: filter, all_count_filter: all_count_filter }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "list_file") when not is_nil(role) do
    authorized_args = AccessRequest.to_authorized_args(request, :list)

    if authorized_args[:filter][:collection_id] do
      filter = Map.merge(authorized_args[:filter], %{ status: "uploaded" })
      all_count_filter = Map.take(filter, [:status, :collection_id])
      authorized_args = %{ authorized_args | filter: filter, all_count_filter: all_count_filter }

      {:ok, authorized_args}
    else
      {:error, :access_denied}
    end
  end

  def authorize(request = %{ role: "anonymous" }, "create_file"), do: {:error, :access_denied}

  def authorize(request = %{ user: user, role: role }, "create_file") when not is_nil(role) do
    authorized_args = AccessRequest.to_authorized_args(request, :create)
    fields = if user do
      Map.merge(authorized_args[:fields], %{ "user_id" => user.id })
    else
      authorized_args[:fields]
    end

    authorized_args = %{ authorized_args | fields: fields }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: "anonymous" }, "get_file"), do: {:error, :access_denied}

  def authorize(request = %{ role: role }, "get_file") when not is_nil(role) do
    authorized_args = AccessRequest.to_authorized_args(request, :get)

    identifiers = Map.merge(authorized_args[:identifiers], %{ status: "uploaded" })
    authorized_args = %{ authorized_args | identifiers: identifiers }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: "anonymous" }, "update_file"), do: {:error, :access_denied}

  def authorize(request = %{ role: role }, "update_file") when role in ["guest", "customer"] do
    authorized_args = AccessRequest.to_authorized_args(request, :update)

    fields = Map.take(authorized_args, [:status])
    authorized_args = %{ authorized_args | fields: fields }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "update_file") when not is_nil(role) do
    {:ok, AccessRequest.to_authorized_args(request, :update)}
  end

  def authorize(request = %{ role: role }, "delete_file") when role in ["anonymous", "guest"], do: {:error, :access_denied}

  def authorize(request = %{ role: role }, "delete_file") when role in ["developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :delete)}
  end

  def authorize(request = %{ account: account, user: user, role: role }, "delete_file") when not is_nil(role) do
    authorized_args = AccessRequest.to_authorized_args(request, :delete)

    file = Service.get_file(%{ id: authorized_args[:id], user_id: user.id }, %{ account: account })
    if file do
      {:ok, authorized_args}
    else
      {:error, :access_denied}
    end
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
