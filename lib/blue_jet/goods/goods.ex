defmodule BlueJet.Goods do
  use BlueJet, :context

  alias BlueJet.Identity
  alias BlueJet.Goods.Stockable
  alias BlueJet.Goods.Unlockable
  alias BlueJet.Goods.Depositable

  ####
  # Stockable
  ####
  def list_stockable(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.list_stockable") do
      do_list_stockable(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_list_stockable(request = %AccessRequest{ vas: %{ account_id: account_id }, filter: filter, pagination: pagination }) do
    query =
      Stockable
      |> search([:name, :print_name, :code, :id], request.search, request.locale, account_id)
      |> filter_by(status: filter[:status])
      |> Stockable.Query.for_account(account_id)
    result_count = Repo.aggregate(query, :count, :id)

    total_query = Stockable |> Stockable.Query.for_account(account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: pagination[:size], number: pagination[:number])

    stockables =
      Repo.all(query)
      |> Repo.preload(Stockable.Query.preloads(request.preloads))
      |> Translation.translate(request.locale)

    response = %AccessResponse{
      meta: %{
        total_count: total_count,
        result_count: result_count,
      },
      data: stockables
    }

    {:ok, response}
  end

  def create_stockable(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.create_stockable") do
      do_create_stockable(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_create_stockable(request = %AccessRequest{ vas: vas }) do
    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })
    changeset = Stockable.changeset(%Stockable{}, fields)

    with {:ok, stockable} <- Repo.insert(changeset) do
      stockable = Repo.preload(stockable, Stockable.Query.preloads(request.preloads))
      {:ok, %AccessResponse{ data: stockable }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def get_stockable(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.get_stockable") do
      do_get_stockable(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_get_stockable(request = %AccessRequest{ vas: vas, params: %{ "id" => id } }) do
    stockable = Stockable |> Stockable.Query.for_account(vas[:account_id]) |> Repo.get(id)

    if stockable do
      stockable =
        stockable
        |> Repo.preload(Stockable.Query.preloads(request.preloads))
        |> Translation.translate(request.locale)

      {:ok, %AccessResponse{ data: stockable }}
    else
      {:error, :not_found}
    end
  end

  def update_stockable(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.update_stockable") do
      do_update_stockable(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_update_stockable(request = %AccessRequest{ vas: vas, params: %{ "id" => id }}) do
    stockable = Stockable |> Stockable.Query.for_account(vas[:account_id]) |> Repo.get(id)

    with %Stockable{} <- stockable,
         changeset <- Stockable.changeset(stockable, request.fields, request.locale),
        {:ok, stockable} <- Repo.update(changeset)
    do
      stockable =
        stockable
        |> Repo.preload(Stockable.Query.preloads(request.preloads))
        |> Translation.translate(request.locale)

      {:ok, %AccessResponse{ data: stockable }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}
      nil ->
        {:error, :not_found}
    end
  end

  def delete_stockable(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.delete_stockable") do
      do_delete_stockable(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_delete_stockable(%AccessRequest{ vas: vas, params: %{ "id" => id } }) do
    stockable = Stockable |> Stockable.Query.for_account(vas[:account_id]) |> Repo.get!(id)

    if stockable do
      Repo.delete!(stockable)
      {:ok, %AccessResponse{}}
    else
      {:error, :not_found}
    end
  end

  ####
  # Unlockable
  ####
  def list_unlockable(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.list_unlockable") do
      do_list_unlockable(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_list_unlockable(request = %AccessRequest{ vas: %{ account_id: account_id }, filter: filter, pagination: pagination }) do
    query =
      Unlockable
      |> search([:name, :print_name, :code, :id], request.search, request.locale, account_id)
      |> filter_by(status: filter[:status])
      |> Unlockable.Query.for_account(account_id)
    result_count = Repo.aggregate(query, :count, :id)

    total_query = Unlockable |> Unlockable.Query.for_account(account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: pagination[:size], number: pagination[:number])

    unlockables =
      Repo.all(query)
      |> Repo.preload(request.preloads)
      |> Translation.translate(request.locale)

    response = %AccessResponse{
      meta: %{
        total_count: total_count,
        result_count: result_count,
      },
      data: unlockables
    }

    {:ok, response}
  end

  def create_unlockable(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.create_unlockable") do
      do_create_unlockable(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_create_unlockable(request = %AccessRequest{ vas: vas }) do
    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })
    changeset = Unlockable.changeset(%Unlockable{}, fields)

    with {:ok, unlockable} <- Repo.insert(changeset) do
      unlockable = Repo.preload(unlockable, Unlockable.Query.preloads(request.preloads))
      {:ok, %AccessResponse{ data: unlockable }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def get_unlockable(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.get_unlockable") do
      do_get_unlockable(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_get_unlockable(request = %AccessRequest{ vas: vas, params: %{ "id" => id } }) do
    unlockable = Unlockable |> Unlockable.Query.for_account(vas[:account_id]) |> Repo.get(id)
    do_get_unlockable_response(unlockable, request)
  end
  def do_get_unlockable(request = %AccessRequest{ vas: vas, params: %{ "code" => code } }) do
    unlockable = Unlockable |> Unlockable.Query.for_account(vas[:account_id]) |> Repo.get_by(code: code)
    do_get_unlockable_response(unlockable, request)
  end
  def do_get_unlockable_response(nil, _), do: {:error, :not_found}
  def do_get_unlockable_response(unlockable, request) do
    unlockable =
      unlockable
      |> Repo.preload(Unlockable.Query.preloads(request.preloads))
      |> Unlockable.put_external_resources(request.preloads)
      |> Translation.translate(request.locale)

    {:ok, %AccessResponse{ data: unlockable }}
  end

  def update_unlockable(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.update_unlockable") do
      do_update_unlockable(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_update_unlockable(request = %{ vas: vas, params: %{ "id" => id }}) do
    unlockable = Unlockable |> Unlockable.Query.for_account(vas[:account_id]) |> Repo.get(id)
    changeset = Unlockable.changeset(unlockable, request.fields, request.locale)

    with %Unlockable{} <- unlockable,
         changeset <- Unlockable.changeset(unlockable, request.fields, request.locale),
        {:ok, unlockable} <- Repo.update(changeset)
    do
      unlockable =
        unlockable
        |> Repo.preload(Unlockable.Query.preloads(request.preloads))
        |> Translation.translate(request.locale)

      {:ok, %AccessResponse{ data: unlockable }}
    else
      nil -> {:error, :not_found}
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def delete_unlockable(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.delete_unlockable") do
      do_delete_unlockable(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_delete_unlockable(%AccessRequest{ vas: vas, params: %{ "id" => id } }) do
    unlockable = Unlockable |> Unlockable.Query.for_account(vas[:account_id]) |> Repo.get!(id)
    if unlockable do
      Repo.delete!(unlockable)
      {:ok, %AccessResponse{}}
    else
      {:error, :not_found}
    end
  end

  ####
  # Point Deposit
  ####
  def list_depositable(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.list_depositable") do
      do_list_depositable(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_list_depositable(request = %AccessRequest{ vas: %{ account_id: account_id }, filter: filter, pagination: pagination }) do
    query =
      Depositable
      |> search([:name, :print_name, :code, :id], request.search, request.locale, account_id)
      |> filter_by(status: filter[:status])
      |> Depositable.Query.for_account(account_id)
    result_count = Repo.aggregate(query, :count, :id)

    total_query = Depositable |> Depositable.Query.for_account(account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: pagination[:size], number: pagination[:number])

    depositables =
      Repo.all(query)
      |> Repo.preload(request.preloads)
      |> Translation.translate(request.locale)

    response = %AccessResponse{
      meta: %{
        total_count: total_count,
        result_count: result_count,
      },
      data: depositables
    }

    {:ok, response}
  end

  def create_depositable(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.create_depositable") do
      do_create_depositable(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_create_depositable(request = %AccessRequest{ vas: vas }) do
    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })
    changeset = Depositable.changeset(%Depositable{}, fields)

    with {:ok, depositable} <- Repo.insert(changeset) do
      depositable = Repo.preload(depositable, Depositable.Query.preloads(request.preloads))
      {:ok, %AccessResponse{ data: depositable }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def get_depositable(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.get_depositable") do
      do_get_depositable(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_get_depositable(request = %AccessRequest{ vas: vas, params: %{ "id" => id } }) do
    depositable = Depositable |> Depositable.Query.for_account(vas[:account_id]) |> Repo.get(id)

    if depositable do
      depositable =
        depositable
        |> Repo.preload(Depositable.Query.preloads(request.preloads))
        |> Depositable.put_external_resources(request.preloads)
        |> Translation.translate(request.locale)

      {:ok, %AccessResponse{ data: depositable }}
    else
      {:error, :not_found}
    end
  end

  def update_depositable(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.update_depositable") do
      do_update_depositable(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_update_depositable(request = %{ vas: vas, params: %{ "id" => id }}) do
    depositable = Depositable |> Depositable.Query.for_account(vas[:account_id]) |> Repo.get(id)
    changeset = Depositable.changeset(depositable, request.fields, request.locale)

    with %Depositable{} <- depositable,
         changeset <- Depositable.changeset(depositable, request.fields, request.locale),
        {:ok, depositable} <- Repo.update(changeset)
    do
      depositable =
        depositable
        |> Repo.preload(Depositable.Query.preloads(request.preloads))
        |> Translation.translate(request.locale)

      {:ok, %AccessResponse{ data: depositable }}
    else
      nil -> {:error, :not_found}
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def delete_depositable(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.delete_depositable") do
      do_delete_depositable(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_delete_depositable(%AccessRequest{ vas: vas, params: %{ "id" => id } }) do
    depositable = Depositable |> Depositable.Query.for_account(vas[:account_id]) |> Repo.get!(id)
    if depositable do
      Repo.delete!(depositable)
      {:ok, %AccessResponse{}}
    else
      {:error, :not_found}
    end
  end
end
