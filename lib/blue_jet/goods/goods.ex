defmodule BlueJet.Goods do
  use BlueJet, :context

  alias BlueJet.Goods.Service

  defp filter_by_role(request = %{ role: role }) when role in ["guest", "customer"] do
    request = %{ request | filter: Map.put(request.filter, :status, "active") }
    %{ request | count_filter: %{ all: %{ status: "active" } } }
  end

  defp filter_by_role(request), do: request

  #
  # MARK: Stockable
  #
  def list_stockable(request) do
    with {:ok, request} <- preprocess_request(request, "goods.list_stockable") do
      request
      |> filter_by_role()
      |> do_list_stockable()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_stockable(request = %{ account: account, filter: filter }) do
    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_stockable(%{ account: account })

    all_count =
      %{ filter: request.count_filter[:all] }
      |> Service.count_stockable(%{ account: account })

    stockables =
      %{ filter: filter, search: request.search }
      |> Service.list_stockable(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count
      },
      data: stockables
    }

    {:ok, response}
  end

  def create_stockable(request) do
    with {:ok, request} <- preprocess_request(request, "goods.create_stockable") do
      request
      |> do_create_stockable()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_stockable(request = %{ account: account }) do
    with {:ok, stockable} <- Service.create_stockable(request.fields, get_sopts(request)) do
      stockable = Translation.translate(stockable, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: stockable }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_stockable(request) do
    with {:ok, request} <- preprocess_request(request, "goods.get_stockable") do
      request
      |> do_get_stockable()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_stockable(request = %{ account: account, params: params }) do
    stockable =
      atom_map(params)
      |> Service.get_stockable(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    if stockable do
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: stockable }}
    else
      {:error, :not_found}
    end
  end

  def update_stockable(request) do
    with {:ok, request} <- preprocess_request(request, "goods.update_stockable") do
      request
      |> do_update_stockable()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_stockable(request = %{ account: account, params: %{ "id" => id } }) do
    with {:ok, stockable} <- Service.update_stockable(id, request.fields, get_sopts(request)) do
      stockable = Translation.translate(stockable, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: stockable }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_stockable(request) do
    with {:ok, request} <- preprocess_request(request, "goods.delete_stockable") do
      request
      |> do_delete_stockable()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_stockable(%{ account: account, params: %{ "id" => id } }) do
    with {:ok, _} <- Service.delete_stockable(id, %{ account: account }) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # MARK: Unlockable
  #
  def list_unlockable(request) do
    with {:ok, request} <- preprocess_request(request, "goods.list_unlockable") do
      request
      |> filter_by_role()
      |> do_list_unlockable()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_unlockable(request = %{ account: account, filter: filter }) do
    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_unlockable(%{ account: account })

    all_count =
      %{ filter: request.count_filter[:all] }
      |> Service.count_unlockable(%{ account: account })

    unlockables =
      %{ filter: filter, search: request.search }
      |> Service.list_unlockable(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count
      },
      data: unlockables
    }

    {:ok, response}
  end

  def create_unlockable(request) do
    with {:ok, request} <- preprocess_request(request, "goods.create_unlockable") do
      request
      |> do_create_unlockable()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_unlockable(request = %{ account: account }) do
    with {:ok, unlockable} <- Service.create_unlockable(request.fields, get_sopts(request)) do
      unlockable = Translation.translate(unlockable, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: unlockable }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_unlockable(request) do
    with {:ok, request} <- preprocess_request(request, "goods.get_unlockable") do
      request
      |> do_get_unlockable()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_unlockable(request = %AccessRequest{ account: account, params: params }) do
    unlockable =
      atom_map(params)
      |> Service.get_unlockable(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    if unlockable do
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: unlockable }}
    else
      {:error, :not_found}
    end
  end

  def update_unlockable(request) do
    with {:ok, request} <- preprocess_request(request, "goods.update_unlockable") do
      request
      |> do_update_unlockable()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_unlockable(request = %{ account: account, params: %{ "id" => id }}) do
    with {:ok, unlockable} <- Service.update_unlockable(id, request.fields, get_sopts(request)) do
      unlockable = Translation.translate(unlockable, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: unlockable }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_unlockable(request) do
    with {:ok, request} <- preprocess_request(request, "goods.delete_unlockable") do
      request
      |> do_delete_unlockable()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_unlockable(%{ account: account, params: %{ "id" => id } }) do
    with {:ok, _} <- Service.delete_unlockable(id, %{ account: account }) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # MARK: Depositable
  #
  def list_depositable(request) do
    with {:ok, request} <- preprocess_request(request, "goods.list_depositable") do
      request
      |> filter_by_role()
      |> do_list_depositable()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_depositable(request = %{ account: account, filter: filter }) do
    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_depositable(%{ account: account })

    all_count =
      %{ filter: request.count_filter[:all] }
      |> Service.count_depositable(%{ account: account })

    depositables =
      %{ filter: filter, search: request.search }
      |> Service.list_depositable(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count
      },
      data: depositables
    }

    {:ok, response}
  end

  def create_depositable(request) do
    with {:ok, request} <- preprocess_request(request, "goods.create_depositable") do
      request
      |> do_create_depositable()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_depositable(request = %{ account: account }) do
    with {:ok, depositable} <- Service.create_depositable(request.fields, get_sopts(request)) do
      depositable = Translation.translate(depositable, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: depositable }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_depositable(request) do
    with {:ok, request} <- preprocess_request(request, "goods.get_depositable") do
      request
      |> do_get_depositable()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_depositable(request = %{ account: account, params: params }) do
    depositable =
      atom_map(params)
      |> Service.get_depositable(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    if depositable do
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: depositable }}
    else
      {:error, :not_found}
    end
  end

  def update_depositable(request) do
    with {:ok, request} <- preprocess_request(request, "goods.update_depositable") do
      request
      |> do_update_depositable()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_depositable(request = %{ account: account, params: %{ "id" => id }}) do
    with {:ok, depositable} <- Service.update_depositable(id, request.fields, get_sopts(request)) do
      depositable = Translation.translate(depositable, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: depositable }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_depositable(request) do
    with {:ok, request} <- preprocess_request(request, "goods.delete_depositable") do
      request
      |> do_delete_depositable()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_depositable(%AccessRequest{ account: account, params: %{ "id" => id } }) do
    with {:ok, _} <- Service.delete_depositable(id, %{ account: account }) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end
end
