defmodule BlueJet.FileStorage.DefaultService do
  use BlueJet, :service

  alias Ecto.Multi
  alias BlueJet.FileStorage.{File, FileCollection, FileCollectionMembership}

  @behaviour BlueJet.FileStorage.Service

  #
  # MARK: File
  #
  def list_file(fields \\ %{}, opts) do
    list(File, fields, opts)
    |> File.put_url()
  end

  def count_file(fields \\ %{}, opts) do
    count(File, fields, opts)
  end

  def create_file(fields, opts) do
    case create(File, fields, opts)  do
      {:ok, file} ->
        {:ok, File.put_url(file)}

      other -> other
    end
  end

  def get_file(identifiers, opts) do
    get(File, identifiers, opts)
    |> File.put_url()
  end

  def update_file(nil, _, _), do: {:error, :not_found}

  def update_file(file = %File{}, fields, opts) do
    case update(file, fields, opts)  do
      {:ok, file} ->
        {:ok, File.put_url(file)}

      other -> other
    end
  end

  def update_file(identifiers, fields, opts) do
    get(File, identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> update_file(fields, opts)
  end

  def delete_file(nil, _), do: {:error, :not_found}

  def delete_file(file = %File{}, opts) do
    account = extract_account(opts)

    changeset =
      %{ file | account: account }
      |> File.changeset(:delete)

    statements =
      Multi.new()
      |> Multi.delete(:file, changeset)
      |> Multi.run(:_, fn(%{ file: file }) ->
          File.delete_s3_object(file)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ file: file }} ->
        {:ok, file}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def delete_file(identifiers, opts) do
    get(File, identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> delete_file(opts)
  end

  def delete_all_file(opts = %{ account: account = %{ mode: "test" } }) do
    batch_size = opts[:batch_size] || 500

    files =
      File.Query.default()
      |> for_account(account.id)
      |> paginate(size: batch_size, number: 1)
      |> Repo.all()

    file_ids = Enum.map(files, fn(file) -> file.id end)

    File.Query.default()
    |> File.Query.filter_by(%{ id: file_ids })
    |> Repo.delete_all()

    File.delete_s3_object(files)

    if length(file_ids) === batch_size do
      delete_all_file(opts)
    else
      :ok
    end
  end

  #
  # MARK: File Collection
  #
  def list_file_collection(fields \\ %{}, opts) do
    list(FileCollection, fields, opts)
    |> FileCollection.put_file_urls()
    |> FileCollection.put_file_count()
  end

  def count_file_collection(fields \\ %{}, opts) do
    count(FileCollection, fields, opts)
  end

  def create_file_collection(fields, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)

    changeset =
      %FileCollection{ account_id: account.id, account: account }
      |> FileCollection.changeset(:insert, fields)

    statements =
      Multi.new()
      |> Multi.insert(:file_collection, changeset)
      |> Multi.run(:_, fn(%{ file_collection: file_collection }) ->
          FileCollection.create_memberships_for_file_ids(file_collection)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ file_collection: file_collection }} ->
        file_collection =
          file_collection
          |> preload(preloads[:path], preloads[:opts])
          |> FileCollection.put_file_urls()

        {:ok, file_collection}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def get_file_collection(identifiers, opts) do
    get(FileCollection, identifiers, opts)
    |> FileCollection.put_file_urls()
    |> FileCollection.put_file_count()
  end

  def update_file_collection(nil, _, _), do: {:error, :not_found}

  def update_file_collection(file_collection = %FileCollection{}, fields, opts) do
    case update(file_collection, fields, opts)  do
      {:ok, file_collection} ->
        file_collection =
          file_collection
          |> FileCollection.put_file_urls()
          |> FileCollection.put_file_count()

        {:ok, file_collection}

      other -> other
    end
  end

  def update_file_collection(identifiers, fields, opts) do
    get(FileCollection, identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> update_file_collection(fields, opts)
  end

  def delete_file_collection(nil, _), do: {:error, :not_found}

  def delete_file_collection(file_collection = %FileCollection{}, opts) do
    delete(file_collection, opts)
  end

  def delete_file_collection(identifiers, opts) do
    get(FileCollection, identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> delete_file_collection(opts)
  end

  def delete_all_file_collection(opts = %{ account: account = %{ mode: "test" } }) do
    batch_size = opts[:batch_size] || 1000

    file_collection_ids =
      FileCollection.Query.default()
      |> for_account(account.id)
      |> paginate(size: batch_size, number: 1)
      |> id_only()
      |> Repo.all()

    FileCollection.Query.default()
    |> FileCollection.Query.filter_by(%{ id: file_collection_ids })
    |> Repo.delete_all()

    if length(file_collection_ids) === batch_size do
      delete_all_file_collection(opts)
    else
      :ok
    end
  end

  #
  # MARK: File Collection Membership
  #
  def create_file_collection_membership(fields, opts) do
    create(FileCollectionMembership, fields, opts)
  end

  def update_file_collection_membership(nil, _, _), do: {:error, :not_found}

  def update_file_collection_membership(fcm = %FileCollectionMembership{}, fields, opts) do
    update(fcm, fields, opts)
  end

  def update_file_collection_membership(identifiers, fields, opts) do
    get(FileCollectionMembership, identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> update_file_collection_membership(fields, opts)
  end

  def delete_file_collection_membership(nil, _), do: {:error, :not_found}

  def delete_file_collection_membership(fcm = %FileCollectionMembership{}, opts) do
    delete(fcm, opts)
  end

  def delete_file_collection_membership(identifiers, opts) do
    get(FileCollectionMembership, identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> delete_file_collection_membership(opts)
  end
end