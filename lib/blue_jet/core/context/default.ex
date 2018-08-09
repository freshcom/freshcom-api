defmodule BlueJet.Context.Default do
  alias BlueJet.{Translation, AccessResponse}

  def list(type, request, module) do
    count_function = String.to_atom("count_" <> type)
    list_function = String.to_atom("list_" <> type)
    policy_module = Module.concat([module, Policy])
    service_module = Module.concat([module, Service])

    with {:ok, args} <- policy_module.authorize(request, "list_" <> type) do
      fields = %{ filter: args[:filter], search: args[:search] }

      total_count = apply(service_module, count_function, [fields, args[:opts]])
      all_count = apply(service_module, count_function, [%{ filter: args[:all_count_filter] }, args[:opts]])

      resources =
        apply(service_module, list_function, [fields, args[:opts]])
        |> Translation.translate(args[:locale], args[:default_locale])

      response = %AccessResponse{
        meta: %{
          locale: args[:locale],
          all_count: all_count,
          total_count: total_count
        },
        data: resources
      }

      {:ok, response}
    else
      other -> other
    end
  end

  def create(type, request, module) do
    create_function = String.to_atom("create_" <> type)
    policy_module = Module.concat([module, Policy])
    service_module = Module.concat([module, Service])

    with {:ok, args} <- policy_module.authorize(request, "create_" <> type),
         {:ok, resource} <- apply(service_module, create_function, [args[:fields], args[:opts]])
    do
      response = %AccessResponse{
        meta: %{ locale: args[:locale] },
        data: resource
      }

      {:ok, response}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get(type, request, module) do
    get_function = String.to_atom("get_" <> type)
    policy_module = Module.concat([module, Policy])
    service_module = Module.concat([module, Service])

    with {:ok, args} <- policy_module.authorize(request, "get_" <> type),
         resource = %{} <- apply(service_module, get_function, [args[:identifiers], args[:opts]])
    do
      resource = Translation.translate(resource, args[:locale], args[:default_locale])

      response = %AccessResponse{
        meta: %{ locale: args[:locale] },
        data: resource
      }

      {:ok, response}
    else
      nil -> {:error, :not_found}

      other -> other
    end
  end

  def update(type, request, module) do
    update_function = String.to_atom("update_" <> type)
    policy_module = Module.concat([module, Policy])
    service_module = Module.concat([module, Service])

    with {:ok, args} <- policy_module.authorize(request, "update_" <> type),
         {:ok, resource} <- apply(service_module, update_function, [args[:identifiers], args[:fields], args[:opts]])
    do
      resource = Translation.translate(resource, args[:locale], args[:default_locale])

      response = %AccessResponse{
        meta: %{ locale: args[:locale] },
        data: resource
      }

      {:ok, response}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete(type, request, module) do
    delete_function = String.to_atom("delete_" <> type)
    policy_module = Module.concat([module, Policy])
    service_module = Module.concat([module, Service])

    with {:ok, args} <- policy_module.authorize(request, "delete_" <> type),
         {:ok, _} <- apply(service_module, delete_function, [args[:identifiers], args[:opts]])
    do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end
end