defmodule BlueJet.FileStorage.Service do
  use BlueJet, :service

  import BlueJet.ControlFlow
  import BlueJet.Utils, only: [atomize_keys: 2]

  alias Ecto.Multi
  alias BlueJet.FileStorage.{File, FileCollection, FileCollectionMembership}

  #
  # MARK: File
  #
  def list_file(query \\ %{}, opts) do
    default_list(File.Query, query, opts)
    |> File.put_url()
  end

  def count_file(query \\ %{}, opts), do: default_count(File.Query, query, opts)

  def create_file(fields, opts) do
    default_create(File, fields, opts)
    ~> File.put_url()
  end

  def get_file(identifiers, opts) do
    default_get(File.Query, identifiers, opts)
    |> File.put_url()
  end

  def update_file(identifiers, fields, opts) do
    default_update(identifiers, fields, opts, &get_file/2)
    ~> File.put_url()
  end

  def delete_file(nil, _), do: {:error, :not_found}

  def delete_file(%File{} = file, opts) do
    account = extract_account(opts)

    changeset =
      %{file | account: account}
      |> File.changeset(:delete)

    statements =
      Multi.new()
      |> Multi.delete(:file, changeset)
      |> Multi.run(:_, &File.Proxy.delete_s3_object(&1[:file]))

    case Repo.transaction(statements) do
      {:ok, %{file: file}} ->
        {:ok, file}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def delete_file(identifiers, opts) do
    get_file(identifiers, Map.drop(opts, [:preload]))
    |> delete_file(opts)
  end

  def delete_all_file(opts = %{account: account = %{mode: "test"}}) do
    batch_size = opts[:batch_size] || 500

    files =
      File.Query.default()
      |> for_account(account.id)
      |> paginate(size: batch_size, number: 1)
      |> Repo.all()

    file_ids = Enum.map(files, fn file -> file.id end)

    File.Query.default()
    |> File.Query.filter_by(%{id: file_ids})
    |> Repo.delete_all()

    File.Proxy.delete_s3_object(files)

    if length(file_ids) === batch_size do
      delete_all_file(opts)
    else
      :ok
    end
  end

  #
  # MARK: File Collection
  #
  def list_file_collection(query \\ %{}, opts) do
    default_list(FileCollection.Query, query, opts)
    |> FileCollection.put_file_urls()
    |> FileCollection.put_file_count()
  end

  def count_file_collection(query \\ %{}, opts), do: default_count(FileCollection.Query, query, opts)

  def create_file_collection(fields, opts) do
    account = extract_account(opts)
    preload = extract_preload(opts)

    changeset =
      %FileCollection{account_id: account.id, account: account}
      |> FileCollection.changeset(:insert, fields)

    statements =
      Multi.new()
      |> Multi.insert(:file_collection, changeset)
      |> Multi.run(:_, &create_memberships(&1[:file_collection]))

    case Repo.transaction(statements) do
      {:ok, %{file_collection: collection}} ->
        collection =
          collection
          |> preload(preload[:paths], preload[:opts])
          |> FileCollection.put_file_urls()

        {:ok, collection}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  defp create_memberships(collection) do
    sort_index_step = 10000

    Enum.reduce(collection.file_ids, 10000, fn(file_id, acc) ->
      Repo.insert!(%FileCollectionMembership{
        account_id: collection.account_id,
        collection_id: collection.id,
        file_id: file_id,
        sort_index: acc
      })

      acc + sort_index_step
    end)

    {:ok, collection}
  end

  def get_file_collection(identifiers, opts) do
    default_get(FileCollection.Query, identifiers, opts)
    |> FileCollection.put_file_urls()
    |> FileCollection.put_file_count()
  end

  def update_file_collection(identifiers, fields, opts) do
    default_update(identifiers, fields, opts, &get_file_collection/2)
    ~> FileCollection.put_file_urls()
    ~> FileCollection.put_file_count()
  end

  def delete_file_collection(identifiers, opts), do: default_delete(identifiers, opts, &get_file_collection/2)
  def delete_all_file_collection(opts), do: default_delete_all(FileCollection, opts)

  #
  # MARK: File Collection Membership
  #
  def list_file_collection_membership(query \\ %{}, opts) do
    account = extract_account(opts)
    pagination = extract_pagination(opts)
    preload = extract_preload(opts)
    filter = atomize_keys(query[:filter], FileCollectionMembership.Query.filterable_fields() ++ [:file_status])

    FileCollectionMembership.Query.default()
    |> FileCollectionMembership.Query.filter_by(filter)
    |> FileCollectionMembership.Query.with_file_status(filter[:file_status])
    |> for_account(account.id)
    |> paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preload[:paths], preload[:opts])
  end

  def count_file_collection_membership(query \\ %{}, opts) do
    account = extract_account(opts)
    filter = atomize_keys(query[:filter], FileCollectionMembership.Query.filterable_fields() ++ [:file_status])

    FileCollectionMembership.Query.default()
    |> FileCollectionMembership.Query.filter_by(filter)
    |> FileCollectionMembership.Query.with_file_status(filter[:file_status])
    |> for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_file_collection_membership(fields, opts),
    do: default_create(FileCollectionMembership, fields, opts)

  def get_file_collection_membership(identifiers, opts),
    do: default_get(FileCollectionMembership.Query, identifiers, opts)

  def update_file_collection_membership(identifiers, fields, opts),
    do: default_update(identifiers, fields, opts, &get_file_collection_membership/2)

  def delete_file_collection_membership(identifiers, opts),
    do: default_delete(identifiers, opts, &get_file_collection_membership/2)
end
