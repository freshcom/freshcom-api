defmodule BlueJet.Inventory do
  use BlueJet.Web, :context

  alias BlueJet.Sku
  alias BlueJet.Unlockable

  ####
  # Sku
  ####
  def create_sku(request = %{ vas: vas }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)

    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })
    changeset = Sku.changeset(%Sku{}, fields)

    with {:ok, sku} <- Repo.insert(changeset) do
      sku = Repo.preload(sku, request.preloads)
      {:ok, sku}
    else
      other -> other
    end
  end

  def get_sku!(request = %{ vas: vas, sku_id: sku_id }) do
    defaults = %{ locale: "en", preloads: [] }
    request = Map.merge(defaults, request)

    sku =
      Sku
      |> Repo.get_by!(account_id: vas[:account_id], id: sku_id)
      |> Repo.preload(request.preloads)
      |> Translation.translate(request.locale)

    sku
  end

  def update_sku(request = %{ vas: vas, sku_id: sku_id }) do
    defaults = %{ preloads: [], fields: %{}, locale: "en" }
    request = Map.merge(defaults, request)

    sku = Repo.get_by!(Sku, account_id: vas[:account_id], id: sku_id)
    changeset = Sku.changeset(sku, request.fields, request.locale)

    with {:ok, sku} <- Repo.update(changeset) do
      sku =
        sku
        |> Repo.preload(request.preloads)
        |> Translation.translate(request.locale)

      {:ok, sku}
    else
      other -> other
    end
  end

  def list_skus(request = %{ vas: vas }) do
    defaults = %{ search_keyword: "", filter: %{}, page_size: 25, page_number: 1, locale: "en", preloads: [] }
    request = Map.merge(defaults, request)
    account_id = vas[:account_id]

    query =
      Sku
      |> search([:name, :print_name, :code, :id], request.search_keyword, request.locale)
      |> filter_by(status: request.filter[:status])
      |> where([s], s.account_id == ^account_id)
    result_count = Repo.aggregate(query, :count, :id)

    total_query = Sku |> where([s], s.account_id == ^account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: request.page_size, number: request.page_number)

    skus =
      Repo.all(query)
      |> Repo.preload(request.preloads)
      |> Translation.translate(request.locale)

    %{
      total_count: total_count,
      result_count: result_count,
      skus: skus
    }
  end

  def delete_sku!(%{ vas: vas, sku_id: sku_id }) do
    sku = Repo.get_by!(Sku, account_id: vas[:account_id], id: sku_id)
    Repo.delete!(sku)
  end

  ####
  # Unlockable
  ####
  def create_unlockable(request = %{ vas: vas }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)

    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })
    changeset = Unlockable.changeset(%Unlockable{}, fields)

    with {:ok, unlockable} <- Repo.insert(changeset) do
      unlockable = Repo.preload(unlockable, request.preloads)
      {:ok, unlockable}
    else
      other -> other
    end
  end

  def get_unlockable!(request = %{ vas: vas, unlockable_id: unlockable_id }) do
    defaults = %{ locale: "en", preloads: [] }
    request = Map.merge(defaults, request)

    unlockable =
      Unlockable
      |> Repo.get_by!(account_id: vas[:account_id], id: unlockable_id)
      |> Repo.preload(request.preloads)
      |> Translation.translate(request.locale)

    unlockable
  end

  def update_unlockable(request = %{ vas: vas, unlockable_id: unlockable_id }) do
    defaults = %{ preloads: [], fields: %{}, locale: "en" }
    request = Map.merge(defaults, request)

    unlockable = Repo.get_by!(Unlockable, account_id: vas[:account_id], id: unlockable_id)
    changeset = Unlockable.changeset(unlockable, request.fields, request.locale)

    with {:ok, unlockable} <- Repo.update(changeset) do
      unlockable =
        unlockable
        |> Repo.preload(request.preloads)
        |> Translation.translate(request.locale)

      {:ok, unlockable}
    else
      other -> other
    end
  end

  def list_unlockables(request = %{ vas: vas }) do
    defaults = %{ search_keyword: "", filter: %{}, page_size: 25, page_number: 1, locale: "en", preloads: [] }
    request = Map.merge(defaults, request)
    account_id = vas[:account_id]

    query =
      Unlockable
      |> search([:name, :print_name, :code, :id], request.search_keyword, request.locale)
      |> filter_by(status: request.filter[:status])
      |> where([s], s.account_id == ^account_id)
    result_count = Repo.aggregate(query, :count, :id)

    total_query = Unlockable |> where([s], s.account_id == ^account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: request.page_size, number: request.page_number)

    unlockables =
      Repo.all(query)
      |> Repo.preload(request.preloads)
      |> Translation.translate(request.locale)

    %{
      total_count: total_count,
      result_count: result_count,
      unlockables: unlockables
    }
  end

  def delete_unlockable!(%{ vas: vas, unlockable_id: unlockable_id }) do
    unlockable = Repo.get_by!(Unlockable, account_id: vas[:account_id], id: unlockable_id)
    Repo.delete!(unlockable)
  end
end
