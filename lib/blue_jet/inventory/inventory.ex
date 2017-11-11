defmodule BlueJet.Inventory do
  use BlueJet, :context

  alias BlueJet.Identity
  alias BlueJet.Inventory.Sku
  alias BlueJet.Inventory.Unlockable

  ####
  # Sku
  ####
  def list_sku(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.list_sku") do
      do_list_sku(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_list_sku(request = %AccessRequest{ vas: %{ account_id: account_id }, filter: filter, pagination: pagination }) do
    query =
      Sku
      |> search([:name, :print_name, :code, :id], request.search, request.locale)
      |> filter_by(status: filter[:status])
      |> Sku.Query.for_account(account_id)
    result_count = Repo.aggregate(query, :count, :id)

    total_query = Sku |> Sku.Query.for_account(account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: pagination[:size], number: pagination[:number])

    skus =
      Repo.all(query)
      |> Repo.preload(Sku.Query.preloads(request.preloads))
      |> Translation.translate(request.locale)

    response = %AccessResponse{
      meta: %{
        total_count: total_count,
        result_count: result_count,
      },
      data: skus
    }

    {:ok, response}
  end

  def create_sku(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.create_sku") do
      do_create_sku(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_create_sku(request = %AccessRequest{ vas: vas }) do
    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })
    changeset = Sku.changeset(%Sku{}, fields)

    with {:ok, sku} <- Repo.insert(changeset) do
      sku = Repo.preload(sku, Sku.Query.preloads(request.preloads))
      {:ok, %AccessResponse{ data: sku }}
    else
      {:error, changeset} ->
        errors = Enum.into(changeset.errors, %{})
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def get_sku(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.get_sku") do
      do_get_sku(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_get_sku(request = %AccessRequest{ vas: vas, params: %{ sku_id: sku_id } }) do
    sku = Sku |> Sku.Query.for_account(vas[:account_id]) |> Repo.get(sku_id)

    if sku do
      sku =
        sku
        |> Repo.preload(Sku.Query.preloads(request.preloads))
        |> Translation.translate(request.locale)

      {:ok, %AccessResponse{ data: sku }}
    else
      {:error, :not_found}
    end
  end

  def update_sku(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.update_sku") do
      do_update_sku(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_update_sku(request = %AccessRequest{ vas: vas, params: %{ sku_id: sku_id }}) do
    sku = Sku |> Sku.Query.for_account(vas[:account_id]) |> Repo.get(sku_id)

    with %Sku{} <- sku,
         changeset <- Sku.changeset(sku, request.fields, request.locale),
        {:ok, sku} <- Repo.update(changeset)
    do
      sku =
        sku
        |> Repo.preload(Sku.Query.preloads(request.preloads))
        |> Translation.translate(request.locale)

      {:ok, %AccessResponse{ data: sku }}
    else
      {:error, changeset} ->
        errors = Enum.into(changeset.errors, %{})
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def delete_sku(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "inventory.delete_sku") do
      do_delete_sku(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_delete_sku(%AccessRequest{ vas: vas, params: %{ sku_id: sku_id } }) do
    sku = Sku |> Sku.Query.for_account(vas[:account_id]) |> Repo.get!(sku_id)

    if sku do
      Repo.delete!(sku)
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
      {:error, changeset} ->
        errors = Enum.into(changeset.errors, %{})
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
      {:error, changeset} ->
        errors = Enum.into(changeset.errors, %{})
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

end
