defmodule BlueJet.Inventory do
  use BlueJet.Web, :context

  alias BlueJet.Sku

  def list_skus(request = %{ account_id: account_id }) do
    defaults = %{ search_keyword: "", filter: %{}, page_size: 25, page_number: 1, locale: "en", include: [] }
    request = Map.merge(defaults, request)

    query =
      Sku
      |> search([:name, :print_name, :id], request.search_keyword, request.locale)
      |> where([s], s.account_id == ^account_id)
    result_count = Repo.aggregate(query, :count, :id)

    total_query = Sku |> where([s], s.account_id == ^account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: request.page_size, number: request.page_number)

    skus =
      Repo.all(query)
      |> Translation.translate_collection(request.locale)

    %{
      total_count: total_count,
      result_count: result_count,
      skus: skus
    }
  end

  def create_sku() do

  end

  def update_sku() do

  end

  def delete_sku() do

  end

end
