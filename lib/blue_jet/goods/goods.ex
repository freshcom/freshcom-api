defmodule BlueJet.Goods do
  use BlueJet, :context

  alias BlueJet.Identity
  alias BlueJet.Goods.Stockable
  alias BlueJet.Goods.Unlockable
  alias BlueJet.Goods.PointDeposit

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
      |> search([:name, :print_name, :code, :id], request.search, request.locale)
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
  def do_get_stockable(request = %AccessRequest{ vas: vas, params: %{ stockable_id: stockable_id } }) do
    stockable = Stockable |> Stockable.Query.for_account(vas[:account_id]) |> Repo.get(stockable_id)

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
  def do_update_stockable(request = %AccessRequest{ vas: vas, params: %{ stockable_id: stockable_id }}) do
    stockable = Stockable |> Stockable.Query.for_account(vas[:account_id]) |> Repo.get(stockable_id)

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
  def do_delete_stockable(%AccessRequest{ vas: vas, params: %{ stockable_id: stockable_id } }) do
    stockable = Stockable |> Stockable.Query.for_account(vas[:account_id]) |> Repo.get!(stockable_id)

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
      |> search([:name, :print_name, :code, :id], request.search, request.locale)
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
  def do_get_unlockable(request = %AccessRequest{ vas: vas, params: %{ unlockable_id: unlockable_id } }) do
    unlockable = Unlockable |> Unlockable.Query.for_account(vas[:account_id]) |> Repo.get(unlockable_id)

    if unlockable do
      unlockable =
        unlockable
        |> Repo.preload(Unlockable.Query.preloads(request.preloads))
        |> Translation.translate(request.locale)

      {:ok, %AccessResponse{ data: unlockable }}
    else
      {:error, :not_found}
    end
  end

  def update_unlockable(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.update_unlockable") do
      do_update_unlockable(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_update_unlockable(request = %{ vas: vas, params: %{ unlockable_id: unlockable_id }}) do
    unlockable = Unlockable |> Unlockable.Query.for_account(vas[:account_id]) |> Repo.get(unlockable_id)
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
  def do_delete_unlockable(%AccessRequest{ vas: vas, params: %{ unlockable_id: unlockable_id } }) do
    unlockable = Unlockable |> Unlockable.Query.for_account(vas[:account_id]) |> Repo.get!(unlockable_id)
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
  def list_point_deposit(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.list_point_deposit") do
      do_list_point_deposit(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_list_point_deposit(request = %AccessRequest{ vas: %{ account_id: account_id }, filter: filter, pagination: pagination }) do
    query =
      PointDeposit
      |> search([:name, :print_name, :code, :id], request.search, request.locale)
      |> filter_by(status: filter[:status])
      |> PointDeposit.Query.for_account(account_id)
    result_count = Repo.aggregate(query, :count, :id)

    total_query = PointDeposit |> PointDeposit.Query.for_account(account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: pagination[:size], number: pagination[:number])

    point_deposits =
      Repo.all(query)
      |> Repo.preload(request.preloads)
      |> Translation.translate(request.locale)

    response = %AccessResponse{
      meta: %{
        total_count: total_count,
        result_count: result_count,
      },
      data: point_deposits
    }

    {:ok, response}
  end

  def create_point_deposit(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.create_point_deposit") do
      do_create_point_deposit(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_create_point_deposit(request = %AccessRequest{ vas: vas }) do
    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })
    changeset = PointDeposit.changeset(%PointDeposit{}, fields)

    with {:ok, point_deposit} <- Repo.insert(changeset) do
      point_deposit = Repo.preload(point_deposit, PointDeposit.Query.preloads(request.preloads))
      {:ok, %AccessResponse{ data: point_deposit }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def get_point_deposit(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.get_point_deposit") do
      do_get_point_deposit(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_get_point_deposit(request = %AccessRequest{ vas: vas, params: %{ id: id } }) do
    point_deposit = PointDeposit |> PointDeposit.Query.for_account(vas[:account_id]) |> Repo.get(id)

    if point_deposit do
      point_deposit =
        point_deposit
        |> Repo.preload(PointDeposit.Query.preloads(request.preloads))
        |> Translation.translate(request.locale)

      {:ok, %AccessResponse{ data: point_deposit }}
    else
      {:error, :not_found}
    end
  end

  def update_point_deposit(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.update_point_deposit") do
      do_update_point_deposit(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_update_point_deposit(request = %{ vas: vas, params: %{ point_deposit_id: point_deposit_id }}) do
    point_deposit = PointDeposit |> PointDeposit.Query.for_account(vas[:account_id]) |> Repo.get(point_deposit_id)
    changeset = PointDeposit.changeset(point_deposit, request.fields, request.locale)

    with %PointDeposit{} <- point_deposit,
         changeset <- PointDeposit.changeset(point_deposit, request.fields, request.locale),
        {:ok, point_deposit} <- Repo.update(changeset)
    do
      point_deposit =
        point_deposit
        |> Repo.preload(PointDeposit.Query.preloads(request.preloads))
        |> Translation.translate(request.locale)

      {:ok, %AccessResponse{ data: point_deposit }}
    else
      nil -> {:error, :not_found}
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def delete_point_deposit(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.delete_point_deposit") do
      do_delete_point_deposit(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_delete_point_deposit(%AccessRequest{ vas: vas, params: %{ point_deposit_id: point_deposit_id } }) do
    point_deposit = PointDeposit |> PointDeposit.Query.for_account(vas[:account_id]) |> Repo.get!(point_deposit_id)
    if point_deposit do
      Repo.delete!(point_deposit)
      {:ok, %AccessResponse{}}
    else
      {:error, :not_found}
    end
  end
end
