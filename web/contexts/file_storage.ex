defmodule BlueJet.FileStorage do
  use BlueJet.Web, :context

  alias BlueJet.ExternalFile
  # alias BlueJet.ExternalFileCollection
  # alias BlueJet.ExternalFileMembership

  ####
  # ExternalFile
  ####
  def create_external_file(request = %{ vas: vas }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)

    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id], "user_id" => vas[:user_id], "customer_id" => vas[:customer_id] })
    changeset = ExternalFile.changeset(%ExternalFile{}, fields)

    with {:ok, external_file} <- Repo.insert(changeset) do
      external_file =
        external_file
        |> Repo.preload(request.preloads)
        |> ExternalFile.put_url()

      {:ok, external_file}
    else
      other -> other
    end
  end

  def get_external_file!(request = %{ vas: vas, external_file_id: ef_id }) do
    defaults = %{ locale: "en", preloads: [] }
    request = Map.merge(defaults, request)

    external_file =
      ExternalFile
      |> Repo.get_by!(account_id: vas[:account_id], id: ef_id)
      |> Repo.preload(request.preloads)
      |> ExternalFile.put_url()

    external_file
  end

  def update_external_file(request = %{ vas: vas, external_file_id: ef_id }) do
    defaults = %{ preloads: [], fields: %{}, locale: "en" }
    request = Map.merge(defaults, request)

    external_file = Repo.get_by!(ExternalFile, account_id: vas[:account_id], id: ef_id)
    changeset = ExternalFile.changeset(external_file, request.fields)

    with {:ok, external_file} <- Repo.update(changeset) do
      external_file =
        external_file
        |> Repo.preload(request.preloads)
        |> ExternalFile.put_url()

      {:ok, external_file}
    else
      other -> other
    end
  end

  def list_external_files(request = %{ vas: vas }) do
    defaults = %{ search_keyword: "", filter: %{}, page_size: 25, page_number: 1, locale: "en", preloads: [] }
    request = Map.merge(defaults, request)
    account_id = vas[:account_id]

    query =
      ExternalFile
      |> search([:name, :id], request.search_keyword, request.locale)
      |> filter_by(status: request.filter[:status])
      |> where([s], s.account_id == ^account_id)
    result_count = Repo.aggregate(query, :count, :id)

    total_query = ExternalFile |> where([s], s.account_id == ^account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: request.page_size, number: request.page_number)

    external_files =
      Repo.all(query)
      |> Repo.preload(request.preloads)

    %{
      total_count: total_count,
      result_count: result_count,
      external_files: external_files
    }
  end
end
