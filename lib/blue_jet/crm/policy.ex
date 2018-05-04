defmodule BlueJet.Crm.Policy do
  alias BlueJet.AccessRequest
  alias BlueJet.Crm.{IdentityService}
  alias BlueJet.Crm.Service

  #
  # MARK: Customer
  #
  def authorize(request = %{ role: role }, "list_customer") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :list)}
  end

  def authorize(request = %{ role: role }, "create_customer") when role in ["guest"] do
    authorized_args = AccessRequest.to_authorized_args(request, :create)

    fields = Map.merge(authorized_args[:fields], %{ "status" => "registered" })
    authorized_args = %{ authorized_args | fields: fields }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "create_customer") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :create)}
  end

  def authorize(request = %{ role: role }, "get_customer") when role in ["guest"] do
    authorized_args = AccessRequest.to_authorized_args(request, :get)

    identifiers =
      authorized_args[:identifiers]
      |> Map.merge(atom_map(request.params))
      |> Map.drop([:id])
    authorized_args = %{ authorized_args | identifiers: identifiers }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "get_customer") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :get)}
  end

  def authorize(request = %{ account: account, user: user, role: role }, "update_customer") when role in ["customer"] do
    authorized_args = AccessRequest.to_authorized_args(request, :update)

    customer = Service.get_customer(%{ user_id: user.id }, %{ account: account })
    authorized_args = %{ authorized_args | id: customer.id }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "update_customer") when role in ["support_specialist", "developer", "administrator"] do
    authorized_args = AccessRequest.to_authorized_args(request, :update)

    opts = Map.merge(authorized_args[:opts], %{ bypass_user_pvc_validation: true })
    authorized_args = %{ authorized_args | opts: opts }

    {:ok, authorized_args}
  end

  def authorize(request = %{ role: role }, "delete_customer") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :delete)}
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

  defp atom_map(m) do
    for {key, val} <- m, into: %{}, do: {String.to_atom(key), val}
  end
end
