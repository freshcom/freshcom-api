defmodule BlueJetWeb.Controller do
  import Phoenix.Controller, only: [render: 3]
  import Plug.Conn, only: [put_status: 2, send_resp: 3]

  alias JaSerializer.Params
  alias BlueJet.{ContextRequest, ContextResponse}

  @type action :: :index | :create | :show | :update | :delete

  @doc """
  Return a default context request according to the action.
  """
  @spec build_context_request(Plug.Conn.t(), action, keyword) :: ContextRequest.t()
  def build_context_request(conn, action, opts \\ [])

  def build_context_request(%{assigns: assigns, params: params}, :index, opts) do
    filter = underscore_value(assigns[:filter], opts[:normalize] || [])

    %ContextRequest{
      vas: assigns[:vas],
      params: Map.take(params, opts[:params] || []),
      search: params["search"],
      filter: filter,
      pagination: %{size: assigns[:page_size], number: assigns[:page_number]},
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }
  end

  def build_context_request(%{assigns: assigns, params: params}, :create, opts) do
    fields =
      params["data"]
      |> Params.to_attributes()
      |> Map.merge(Map.take(params, opts[:fields] || []))
      |> underscore_value(opts[:normalize] || [])

    %ContextRequest{
      vas: assigns[:vas],
      fields: fields,
      preloads: assigns[:preloads]
    }
  end

  def build_context_request(%{assigns: assigns, params: params}, :show, opts) do
    identifiers = extract_identifiers(params, opts)

    %ContextRequest{
      vas: assigns[:vas],
      identifiers: identifiers,
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }
  end

  def build_context_request(%{assigns: assigns, params: params}, :update, opts) do
    identifiers = extract_identifiers(params, opts)
    fields =
      params["data"]
      |> Params.to_attributes()
      |> underscore_value(opts[:normalize] || [])

    %ContextRequest{
      vas: assigns[:vas],
      identifiers: identifiers,
      fields: fields,
      preloads: assigns[:preloads],
      locale: assigns[:locale]
    }
  end

  def build_context_request(%{assigns: assigns, params: params}, :delete, _) do
    %ContextRequest{
      vas: assigns[:vas],
      identifiers: %{id: params["id"]}
    }
  end

  defp extract_identifiers(params, identifiers: valid_keys) do
    valid_keys = Enum.map(valid_keys, &Atom.to_string/1)
    valid_params = Map.take(params, valid_keys)
    Enum.reduce(valid_params, %{}, fn({k, v}, acc) -> Map.put(acc, String.to_atom(k), v) end)
  end

  defp extract_identifiers(params, _) do
    %{id: params["id"]}
  end

  @doc """
  Send the HTTP response if the given contxt result is successful, otherwise return
  an error.
  """
  @spec send_http_response({:ok, ContextResponse.t()} | {:error, any}, Plug.Conn.t(), action, keyword) :: Plug.Conn.t() | {:error, any}
  def send_http_response(context_result, conn, action, opts \\ [])

  def send_http_response({:ok, _}, conn, _, status: :no_content) do
    send_resp(conn, :no_content, "")
  end

  def send_http_response({:ok, %{data: data, meta: meta}}, conn, :index, _) do
    render(conn, "index.json-api", data: data, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])
  end

  def send_http_response({:ok, %{data: data, meta: meta}}, conn, :create, _) do
    conn
    |> put_status(:created)
    |> render("show.json-api", data: data, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])
  end

  def send_http_response({:ok, %{data: data, meta: meta}}, conn, :show, _) do
    render(conn, "show.json-api", data: data, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])
  end

  def send_http_response({:ok, %{data: data, meta: meta}}, conn, :update, _) do
    render(conn, "show.json-api", data: data, opts: [meta: camelize_map(meta), include: conn.query_params["include"]])
  end

  def send_http_response({:ok, _}, conn, :delete, _) do
    send_resp(conn, :no_content, "")
  end

  def send_http_response({:error, %{errors: errors}}, conn, _, _) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(:errors, data: extract_errors(errors))
  end

  def send_http_response(other, _, _, _), do: other

  @doc """
  Perform the default logic for given controller action.
  """
  @spec default(Plug.Conn.t(), action, fun) :: Plug.Conn.t() | {:error, any}
  def default(conn, action, context_fun, opts \\ [])

  def default(conn, :index, context_fun, opts) do
    conn
    |> build_context_request(:index, Keyword.take(opts, [:normalize, :params]))
    |> context_fun.()
    |> send_http_response(conn, :index)
  end

  def default(conn, :create, context_fun, opts) do
    conn
    |> build_context_request(:create, Keyword.take(opts, [:normalize, :fields]))
    |> context_fun.()
    |> send_http_response(conn, :create, Keyword.take(opts, [:status]))
  end

  def default(conn, :show, context_fun, opts) do
    conn
    |> build_context_request(:show, Keyword.take(opts, [:identifiers]))
    |> context_fun.()
    |> send_http_response(conn, :show)
  end

  def default(conn, :update, context_fun, opts) do
    conn
    |> build_context_request(:update, Keyword.take(opts, [:normalize, :identifiers]))
    |> context_fun.()
    |> send_http_response(conn, :update, Keyword.take(opts, [:status]))
  end

  def default(conn, :delete, context_fun, _) do
    conn
    |> build_context_request(:delete)
    |> context_fun.()
    |> send_http_response(conn, :delete)
  end

  def extract_errors(%{ valid?: false, errors: errors }) do
    extract_errors(errors)
  end
  def extract_errors(changeset = %{ valid?: true }), do: changeset
  def extract_errors(errors) do
    Enum.reduce(errors, [], fn({ field, { msg, opts } }, acc) ->
      msg = Enum.reduce(opts, msg, fn({ key, value }, acc) ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)

      title = if opts[:validation] do
        "#{humanize(field)} #{msg}"
      else
        msg
      end

      mc = cond do
        String.contains?(msg, "taken") -> "taken"

        true -> nil
      end

      {vc, meta} = Keyword.pop(opts, :validation)
      {ec, meta} = Keyword.pop(meta, :code)

      code = ec || vc || mc || "invalid"
      error = %{ source: %{ pointer: pointer_for(field) }, code: Inflex.camelize(code, :lower), title: title }

      error =
        case Enum.empty?(meta) do
          true -> error
          _ -> Map.put(error, :meta, Enum.into(meta, %{}))
        end

      acc ++ [error]
    end)
  end

  def humanize(atom) when is_atom(atom), do: humanize(Atom.to_string(atom))
  def humanize(bin) when is_binary(bin) do
    bin =
      if String.ends_with?(bin, "_id") do
        binary_part(bin, 0, byte_size(bin) - 3)
      else
        bin
      end

    bin |> String.replace("_", " ") |> String.capitalize
  end

  def pointer_for(:fields), do: "/data"
  def pointer_for(:attributes), do: "/data/attributes"
  def pointer_for(:relationships), do: "/data/relationships"
  def pointer_for(field) do
    case Regex.run(~r/(.*)_id$/, to_string(field)) do
      nil      -> "/data/attributes/#{Inflex.camelize(field, :lower)}"
      [_, rel] -> "/data/relationships/#{Inflex.camelize(rel, :lower)}"
    end
  end

  def camelize_map(map) do
    Enum.reduce(map, %{}, fn({key, value}, acc) ->
      Map.put(acc, Inflex.camelize(key, :lower), value)
    end)
  end

  def underscore_value(map, keys) do
    Enum.reduce(map, map, fn({k, v}, acc) ->
      if Enum.member?(keys, k) && acc[k] do
        %{ acc | k => Inflex.underscore(v) }
      else
        acc
      end
    end)
  end
end