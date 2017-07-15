defmodule BlueJet.FileStorage do
  use BlueJet.Web, :context

  alias BlueJet.ExternalFile
  alias BlueJet.ExternalFileCollection
  alias BlueJet.ExternalFileCollectionMembership

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

  def delete_external_file!(%{ vas: vas, external_file_id: ef_id }) do
    external_file = Repo.get_by!(ExternalFile, account_id: vas[:account_id], id: ef_id)
    Repo.delete!(external_file)
  end

  ####
  # ExternalFileCollection
  ####
  def create_external_file_collection(request = %{ vas: vas }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)

    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })
    changeset = ExternalFileCollection.changeset(%ExternalFileCollection{}, fields)

    with {:ok, efc} <- Repo.insert(changeset) do
      efc = Repo.preload(efc, request.preloads)
      {:ok, efc}
    else
      other -> other
    end
  end

  def get_external_file_collection!(request = %{ vas: vas, external_file_collection_id: efc_id }) do
    defaults = %{ locale: "en", preloads: [] }
    request = Map.merge(defaults, request)

    efc =
      ExternalFileCollection
      |> Repo.get_by!(account_id: vas[:account_id], id: efc_id)
      |> Repo.preload(request.preloads)
      |> Translation.translate(request.locale)

    efc
  end

  def update_external_file_collection(request = %{ vas: vas, external_file_collection_id: efc_id }) do
    defaults = %{ preloads: [], fields: %{}, locale: "en" }
    request = Map.merge(defaults, request)

    efc = Repo.get_by!(ExternalFileCollection, account_id: vas[:account_id], id: efc_id)
    changeset = ExternalFileCollection.changeset(efc, request.fields, request.locale)

    with {:ok, efc} <- Repo.update(changeset) do
      efc =
        efc
        |> Repo.preload(request.preloads)
        |> Translation.translate(request.locale)

      {:ok, efc}
    else
      other -> other
    end
  end

  def list_external_file_collections(request = %{ vas: vas }) do
    defaults = %{ search_keyword: "", filter: %{}, page_size: 25, page_number: 1, locale: "en", preloads: [] }
    request = Map.merge(defaults, request)
    account_id = vas[:account_id]

    query =
      ExternalFileCollection
      |> search([:name, :label, :id], request.search_keyword, request.locale)
      |> filter_by(label: request.filter[:label], content_type: request.filter[:content_type])
      |> where([s], s.account_id == ^account_id)
    result_count = Repo.aggregate(query, :count, :id)

    total_query = ExternalFileCollection |> where([s], s.account_id == ^account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: request.page_size, number: request.page_number)

    efcs =
      Repo.all(query)
      |> Repo.preload(request.preloads)
      |> Translation.translate(request.locale)

    %{
      total_count: total_count,
      result_count: result_count,
      external_file_collections: efcs
    }
  end

  def delete_external_file_collection!(%{ vas: vas, external_file_collection_id: efc_id }) do
    efc = Repo.get_by!(ExternalFileCollection, account_id: vas[:account_id], id: efc_id)
    Repo.delete!(efc)
  end

  ####
  # ExternalFileCollectionMembership
  ####
  def create_external_file_collection_membership(request = %{ vas: vas }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)

    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })
    changeset = ExternalFileCollectionMembership.changeset(%ExternalFileCollectionMembership{}, fields)

    with {:ok, efcm} <- Repo.insert(changeset) do
      efcm = Repo.preload(efcm, request.preloads)
      {:ok, efcm}
    else
      other -> other
    end
  end

  def update_external_file_collection_membership(request = %{ vas: vas, external_file_collection_membership_id: efcm_id }) do
    defaults = %{ preloads: [], fields: %{}, locale: "en" }
    request = Map.merge(defaults, request)

    efcm = Repo.get_by!(ExternalFileCollectionMembership, account_id: vas[:account_id], id: efcm_id)
    changeset = ExternalFileCollectionMembership.changeset(efcm, request.fields)

    with {:ok, efcm} <- Repo.update(changeset) do
      efcm =
        efcm
        |> Repo.preload(request.preloads)
        |> Translation.translate(request.locale)

      {:ok, efcm}
    else
      other -> other
    end
  end

  def list_external_file_collection_memberships(request = %{ vas: vas }) do
    defaults = %{ filter: %{}, page_size: 25, page_number: 1, locale: "en", preloads: [] }
    request = Map.merge(defaults, request)
    account_id = vas[:account_id]

    query =
      ExternalFileCollectionMembership
      |> filter_by(collection_id: request.filter[:collection_id], file_id: request.filter[:file_id])
      |> where([s], s.account_id == ^account_id)
    result_count = Repo.aggregate(query, :count, :id)

    total_query = ExternalFileCollectionMembership |> where([s], s.account_id == ^account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: request.page_size, number: request.page_number)

    efcms =
      Repo.all(query)
      |> Repo.preload(request.preloads)
      |> Translation.translate(request.locale)

    %{
      total_count: total_count,
      result_count: result_count,
      external_file_collection_memberships: efcms
    }
  end

  def delete_external_file_collection_membership!(%{ vas: vas, external_file_collection_membership_id: efcm_id }) do
    efcm = Repo.get_by!(ExternalFileCollectionMembership, account_id: vas[:account_id], id: efcm_id)
    Repo.delete!(efcm)
  end
end
