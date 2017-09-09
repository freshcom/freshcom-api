defmodule BlueJet.FileStorage do
  use BlueJet, :context

  alias BlueJet.FileStorage.ExternalFile
  alias BlueJet.FileStorage.ExternalFileCollection
  alias BlueJet.FileStorage.ExternalFileCollectionMembership

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
      |> where([ef], ef.account_id == ^account_id)
      |> order_by([ef], desc: ef.updated_at)
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
    ExternalFile.delete_object(external_file)
    Repo.delete!(external_file)
  end

  ####
  # ExternalFileCollection
  ####
  def create_external_file_collection(request = %{ vas: vas }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)
    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })

    with changeset = %{valid?: true} <- ExternalFileCollection.changeset(%ExternalFileCollection{}, fields) do
      {:ok, efc} = Repo.transaction(fn ->
        efc = Repo.insert!(changeset)
        create_efcms!(fields["file_ids"] || [], efc)
      end)

      efc = Repo.preload(efc, request.preloads)
      {:ok, efc}
    else
      other -> {:error, other}
    end
  end

  defp create_efcms!(file_ids, efc, initial_sort_index \\ 10000, sort_index_step \\ 10000) do
    Enum.reduce(file_ids, initial_sort_index, fn(file_id, acc) ->
      changeset = ExternalFileCollectionMembership.changeset(%ExternalFileCollectionMembership{}, %{
        account_id: efc.account_id,
        collection_id: efc.id,
        file_id: file_id,
        sort_index: acc
      })

      if changeset.valid? do
        Repo.insert!(changeset)
      end

      acc + sort_index_step
    end)

    efc
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

    source_file_ids = Ecto.assoc(efc, :files) |> ids_only |> Repo.all
    target_file_ids = request.fields["file_ids"]
    file_ids_to_delete = if target_file_ids do
      source_file_ids -- target_file_ids
    else
      []
    end

    file_ids_to_add = if target_file_ids do
      target_file_ids -- source_file_ids
    else
      []
    end

    with changeset = %{valid?: true} <- ExternalFileCollection.changeset(efc, request.fields, request.locale) do
      {:ok, efc} = Repo.transaction(fn ->
        efc = Repo.update!(changeset)
        delete_efcms!(file_ids_to_delete, efc)
        initial_sort_index = max_efcm_sort_index(efc) + 10000
        create_efcms!(file_ids_to_add, efc, initial_sort_index)
      end)

      efc =
        efc
        |> Repo.preload(request.preloads)
        |> Translation.translate(request.locale)

      {:ok, efc}
    else
      other -> {:error, other}
    end
  end

  defp max_efcm_sort_index(%{ id: efc_id, account_id: account_id }) do
    m_sort_index = from(efcm in ExternalFileCollectionMembership,
      select: max(efcm.sort_index),
      where: efcm.account_id == ^account_id,
      where: efcm.collection_id == ^efc_id)
    |> Repo.one()

    case m_sort_index do
      nil -> 0
      other -> other
    end
  end

  # TODO: need to also delete the s3 object
  defp delete_efcms!(file_ids, efc = %{ id: efc_id, account_id: account_id }) do
    efcms =
      from(efcm in ExternalFileCollectionMembership,
        where: efcm.account_id == ^account_id,
        where: efcm.collection_id == ^efc_id,
        where: efcm.file_id in ^file_ids)
      |> Repo.all()

    efcm_ids = Enum.map(efcms, fn(efcm) -> efcm.id end)
    ef_ids = Enum.map(efcms, fn(efcm) -> efcm.file_id end)
    efs =
      from(ef in ExternalFile,
        where: ef.id in ^ef_ids)
      |> Repo.all()

    Enum.each(efs, fn(ef) ->
      ExternalFile.delete_object(ef)
    end)

    from(efcm in ExternalFileCollectionMembership,
      where: efcm.id in ^efcm_ids)
    |> Repo.delete_all()

    from(ef in ExternalFile,
      where: ef.id in ^ef_ids)
    |> Repo.delete_all()

    efc
  end

  def list_external_file_collections(request = %{ vas: vas }) do
    defaults = %{ search_keyword: "", filter: %{}, page_size: 25, page_number: 1, locale: "en", preloads: [] }
    request = Map.merge(defaults, request)
    account_id = vas[:account_id]

    query =
      ExternalFileCollection
      |> search([:name, :label, :id], request.search_keyword, request.locale)
      |> filter_by(label: request.filter[:label], content_type: request.filter[:content_type])
      |> where([efc], efc.account_id == ^account_id)
      |> order_by([efc], desc: efc.updated_at)
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

  # TODO: use another process to delete, and also need to remove the files
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
    ef = Repo.get!(ExternalFile, efcm.file_id)

    Repo.transaction(fn ->
      ExternalFile.delete_object(ef)
      Repo.delete!(efcm)
      Repo.delete!(ef)
    end)
  end
end
