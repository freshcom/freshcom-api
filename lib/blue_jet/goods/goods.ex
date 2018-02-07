defmodule BlueJet.Goods do
  use BlueJet, :context

  alias BlueJet.Goods.Service

  alias BlueJet.Goods.Stockable
  alias BlueJet.Goods.Unlockable
  alias BlueJet.Goods.Depositable

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

  def do_list_stockable(request = %{ account: account, filter: filter, counts: counts, pagination: pagination }) do
    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_stockable(%{ account: account })

    all_count =
      %{ filter: Map.take(request.count_filter, [:all]) }
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

  def do_get_stockable(request = %{ account: account, params: %{ "id" => id } }) do
    stockable =
      %{ id: id }
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
      |> AccessRequest.transform_by_role()
      |> do_list_unlockable()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_unlockable(request = %{ account: account, filter: filter, counts: counts, pagination: pagination }) do
    data_query =
      Unlockable.Query.default()
      |> search([:name, :code, :id], request.search, request.locale, account.default_locale, Unlockable.translatable_fields())
      |> filter_by(status: filter[:status])
      |> Unlockable.Query.for_account(account.id)

    total_count = Repo.aggregate(data_query, :count, :id)
    all_count =
      Unlockable.Query.default()
      |> filter_by(status: counts[:all][:status])
      |> Unlockable.Query.for_account(account.id)
      |> Repo.aggregate(:count, :id)

    preloads = Unlockable.Query.preloads(request.preloads, role: request.role)
    unlockables =
      data_query
      |> paginate(size: pagination[:size], number: pagination[:number])
      |> Repo.all()
      |> Repo.preload(preloads)
      |> Unlockable.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count,
      },
      data: unlockables
    }

    {:ok, response}
  end

  defp unlockable_response(nil, _), do: {:error, :not_found}

  defp unlockable_response(unlockable, request = %{ account: account }) do
    preloads = Unlockable.Query.preloads(request.preloads, role: request.role)

    unlockable =
      unlockable
      |> Repo.preload(preloads)
      |> Unlockable.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: unlockable }}
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
    case Service.create_unlockable(request.fields, %{ account_id: account.id, account: account, locale: request.locale }) do
      {:ok, unlockable} ->
        unlockable_response(unlockable, request)

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

  def do_get_unlockable(request = %AccessRequest{ account: account, params: %{ "id" => id } }) do
    unlockable =
      Unlockable.Query.default()
      |> Unlockable.Query.for_account(account.id)
      |> Repo.get(id)

    unlockable_response(unlockable, request)
  end

  def do_get_unlockable(request = %AccessRequest{ account: account, params: %{ "code" => code } }) do
    unlockable =
      Unlockable.Query.default()
      |> Unlockable.Query.for_account(account.id)
      |> Repo.get_by(code: code)

    unlockable_response(unlockable, request)
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
    case Service.update_unlockable(id, request.fields, %{ account: account, locale: request.locale }) do
      {:ok, unlockable} ->
        unlockable_response(unlockable, request)

      {:error, %{ errors: errors}} ->
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
    unlockable =
      Unlockable.Query.default()
      |> Unlockable.Query.for_account(account.id)
      |> Repo.get(id)

    if unlockable do
      Repo.delete!(unlockable)
      {:ok, %AccessResponse{}}
    else
      {:error, :not_found}
    end
  end

  #
  # Depositable
  #
  def list_depositable(request) do
    with {:ok, request} <- preprocess_request(request, "goods.list_depositable") do
      request
      |> AccessRequest.transform_by_role()
      |> do_list_depositable()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_depositable(request = %{ account: account, filter: filter, counts: counts, pagination: pagination }) do
    data_query =
      Depositable.Query.default()
      |> search([:name, :code, :id], request.search, request.locale, account.default_locale)
      |> filter_by(status: filter[:status])
      |> Depositable.Query.for_account(account.id)

    total_count = Repo.aggregate(data_query, :count, :id)
    all_count =
      Depositable.Query.default()
      |> filter_by(status: counts[:all][:status])
      |> Depositable.Query.for_account(account.id)
      |> Repo.aggregate(:count, :id)

    preloads = Depositable.Query.preloads(request.preloads, role: request.role)
    depositables =
      data_query
      |> paginate(size: pagination[:size], number: pagination[:number])
      |> Repo.all()
      |> Repo.preload(preloads)
      |> Depositable.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
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

  defp depositable_response(nil, _), do: {:error, :not_found}

  defp depositable_response(depositable, request = %{ account: account }) do
    preloads = Depositable.Query.preloads(request.preloads, role: request.role)

    depositable =
      depositable
      |> Repo.preload(preloads)
      |> Depositable.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: depositable }}
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
    depositable = %Depositable{ account_id: account.id, account: account}
    changeset = Depositable.changeset(depositable, request.fields, request.locale, account.default_locale)

    with {:ok, depositable} <- Repo.insert(changeset) do
      depositable_response(depositable, request)
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

  def do_get_depositable(request = %{ account: account, params: %{ "id" => id } }) do
    depositable =
      Depositable.Query.default()
      |> Depositable.Query.for_account(account.id)
      |> Repo.get(id)

    depositable_response(depositable, request)
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
    depositable =
      Depositable.Query.default()
      |> Depositable.Query.for_account(account.id)
      |> Repo.get(id)
      |> Map.put(:account, account)

    with %Depositable{} <- depositable,
         changeset <- Depositable.changeset(depositable, request.fields, request.locale, account.default_locale),
        {:ok, depositable} <- Repo.update(changeset)
    do
      depositable_response(depositable, request)
    else
      nil -> {:error, :not_found}
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}
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
    depositable =
      Depositable.Query.default()
      |> Depositable.Query.for_account(account.id)
      |> Repo.get(id)

    if depositable do
      Repo.delete!(depositable)
      {:ok, %AccessResponse{}}
    else
      {:error, :not_found}
    end
  end
end
