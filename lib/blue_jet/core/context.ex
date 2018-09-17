defmodule BlueJet.Context do
  alias BlueJet.{Translation, ContextResponse}

  def default(request, cmd, type, policy, service) do
    endpoint = join_atom(cmd, type, "_")

    request
    |> policy.authorize(endpoint)
    |> do_default(cmd, Atom.to_string(type), service)
  end

  defp do_default({:ok, req}, :list, type, service) do
    count_fun = Function.capture(service, String.to_atom("count_" <> type), 2)
    list_fun = Function.capture(service, String.to_atom("list_" <> type), 2)

    %ContextResponse{}
    |> ContextResponse.put_meta(:locale, req.locale)
    |> count_total(req, count_fun)
    |> count_all(req, count_fun)
    |> process_list(req, list_fun)
    |> translate(req.locale, req._default_locale_)
    |> to_tagged_tuple()
  end

  defp do_default({:ok, req}, :create, type, service_or_fun) do
    create_fun = extract_fun(:create, type, service_or_fun)

    %ContextResponse{}
    |> ContextResponse.put_meta(:locale, req.locale)
    |> process_create(req, create_fun)
    |> to_tagged_tuple()
  end

  defp do_default({:ok, req}, :get, type, service) do
    get_fun = Function.capture(service, String.to_atom("get_" <> type), 2)

    %ContextResponse{}
    |> ContextResponse.put_meta(:locale, req.locale)
    |> process_get(req, get_fun)
    |> translate(req.locale, req._default_locale_)
    |> to_tagged_tuple()
  end

  defp do_default({:ok, req}, :update, type, service) do
    update_fun = Function.capture(service, String.to_atom("update_" <> type), 3)

    %ContextResponse{}
    |> ContextResponse.put_meta(:locale, req.locale)
    |> process_update(req, update_fun)
    |> translate(req.locale, req._default_locale_)
    |> to_tagged_tuple()
  end

  defp do_default({:ok, req}, :delete, type, service) do
    delete_fun = Function.capture(service, String.to_atom("delete_" <> type), 2)

    %ContextResponse{}
    |> process_delete(req, delete_fun)
    |> to_tagged_tuple()
  end

  defp do_default(other, _, _, _), do: other

  defp extract_fun(_, _, fun) when is_function(fun) do
    fun
  end

  defp extract_fun(:create, type, service) do
    Function.capture(service, String.to_atom("create_" <> type), 2)
  end

  defp join_atom(atom1, atom2, joiner) do
    string1 = Atom.to_string(atom1)
    string2 = Atom.to_string(atom2)
    String.to_atom(string1 <> joiner <> string2)
  end

  defp count_total(response, req, fun) do
    count = fun.(%{
      filter: req.filter,
      search: req.search,
      locale: req.locale
    }, %{
      account: req._vad_.account
    })

    ContextResponse.put_meta(response, :total_count, count)
  end

  defp count_all(response, req, fun) do
    count = fun.(%{
      filter: req._scope_,
      search: req.search,
      locale: req.locale
    }, %{
      account: req._vad_.account
    })

    ContextResponse.put_meta(response, :all_count, count)
  end

  defp process_list(response, req, fun) do
    data = fun.(%{
      filter: req._scope_,
      search: req.search
    }, %{
      account: req._vad_.account,
      pagination: req.pagination,
      locale: req.locale,
      preload: req._preload_
    })

    %{response | data: data}
  end

  defp process_create(response, req, fun) do
    fun.(req.fields, %{
      account: req._vad_.account,
      preload: req._preload_
    })
    |> to_response(:create, response)
  end

  defp process_get(response, req, fun) do
    opts = Map.merge(req._opts_, %{
      account: req._vad_.account,
      preload: req._preload_
    })

    fun.(req.identifiers, opts)
    |> to_response(:get, response)
  end

  defp process_update(response, req, fun) do
    opts = Map.merge(req._opts_, %{
      account: req._vad_.account,
      locale: req.locale,
      preload: req._preload_
    })

    fun.(req.identifiers, req.fields, opts)
    |> to_response(:update, response)
  end

  defp process_delete(response, req, fun) do
    opts = Map.merge(req._opts_, %{
      account: req._vad_.account
    })

    fun.(req.identifiers, opts)
    |> to_response(:delete, response)
  end

  def to_response({:ok, data}, cmd, resp) when cmd in [:create, :update], do: %{resp | data: data}
  def to_response({:error, %{errors: errors}}, cmd, resp) when cmd in [:create, :update, :delete], do: %{resp | errors: errors}
  def to_response(nil, :get, _), do: {:error, :not_found}
  def to_response(%{} = data, :get, resp), do: %{resp | data: data}
  def to_response({:ok, _}, :delete, resp), do: resp
  def to_response(other, _, _), do: other

  def translate(%{data: data} = response, locale, default_locale) do
    %{response | data: Translation.translate(data, locale, default_locale)}
  end

  def translate(other, _, _), do: other

  def to_tagged_tuple(%{errors: errors} = response) when length(errors) > 0, do: {:error, response}
  def to_tagged_tuple(%ContextResponse{} = response), do: {:ok, response}
  def to_tagged_tuple(other), do: other

  ########
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

      response = %ContextResponse{
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
      response = %ContextResponse{
        meta: %{ locale: args[:locale] },
        data: resource
      }

      {:ok, response}
    else
      {:error, %{ errors: errors }} ->
        {:error, %ContextResponse{ errors: errors }}

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

      response = %ContextResponse{
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

      response = %ContextResponse{
        meta: %{ locale: args[:locale] },
        data: resource
      }

      {:ok, response}
    else
      {:error, %{ errors: errors }} ->
        {:error, %ContextResponse{ errors: errors }}

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
      {:ok, %ContextResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %ContextResponse{ errors: errors }}

      other -> other
    end
  end
end