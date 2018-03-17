defmodule BlueJet.FileStorage.DefaultService do
  use BlueJet, :service

  alias Ecto.Multi
  alias BlueJet.FileStorage.IdentityService
  alias BlueJet.FileStorage.{File, FileCollection, FileCollectionMembership}

  @behaviour BlueJet.FileStorage.Service

  defp get_account(opts) do
    opts[:account] || IdentityService.get_account(opts)
  end

  defp put_account(opts) do
    %{ opts | account: get_account(opts) }
  end

  #
  # MARK: File
  #
  def list_file(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    File.Query.default()
    |> File.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> File.Query.filter_by(filter)
    |> File.Query.for_account(account.id)
    |> File.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> File.put_url()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_file(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    File.Query.default()
    |> File.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> File.Query.filter_by(filter)
    |> File.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_file(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %File{ account_id: account.id, account: account }
      |> File.changeset(:insert, fields)

    with {:ok, file} <- Repo.insert(changeset) do
      file =
        file
        |> File.put_url()
        |> preload(preloads[:path], preloads[:opts])

      {:ok, file}
    else
      other -> other
    end
  end

  def get_file(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    File.Query.default()
    |> File.Query.for_account(account.id)
    |> Repo.get_by(fields)
    |> File.put_url()
    |> preload(preloads[:path], preloads[:opts])
  end

  def update_file(nil, _, _), do: {:error, :not_found}

  def update_file(file = %File{}, fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %{ file | account: account }
      |> File.changeset(:update, fields, opts[:locale])

    with {:ok, file} <- Repo.update(changeset) do
      file =
        file
        |> File.put_url()
        |> preload(preloads[:path], preloads[:opts])

      {:ok, file}
    else
      other -> other
    end
  end

  def update_file(id, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    File
    |> Repo.get_by(id: id, account_id: account.id)
    |> update_file(fields, opts)
  end

  def delete_file(nil, _), do: {:error, :not_found}

  def delete_file(file = %File{}, opts) do
    account = get_account(opts)

    changeset =
      %{ file | account: account }
      |> File.changeset(:delete)

    statements =
      Multi.new()
      |> Multi.delete(:file, changeset)
      |> Multi.run(:processed_file, fn(%{ file: file }) ->
          File.process(file, changeset)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_file: file }} ->
        {:ok, file}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def delete_file(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    File
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_file(opts)
  end

  def delete_all_file(opts = %{ account: account = %{ mode: "test" } }) do
    batch_size = opts[:batch_size] || 500

    files =
      File.Query.default()
      |> File.Query.for_account(account.id)
      |> File.Query.paginate(size: batch_size, number: 1)
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
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    FileCollection.Query.default()
    |> FileCollection.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> FileCollection.Query.filter_by(filter)
    |> FileCollection.Query.for_account(account.id)
    |> FileCollection.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> FileCollection.Query.order_by([desc: :updated_at])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
    |> FileCollection.put_file_urls()
    |> FileCollection.put_file_count()
  end

  def count_file_collection(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    FileCollection.Query.default()
    |> FileCollection.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> FileCollection.Query.filter_by(filter)
    |> FileCollection.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_file_collection(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %FileCollection{ account_id: account.id, account: account }
      |> FileCollection.changeset(:insert, fields)

    statements =
      Multi.new()
      |> Multi.insert(:file_collection, changeset)
      |> Multi.run(:processed_file_collection, fn(%{ file_collection: file_collection }) ->
          FileCollection.process(file_collection, changeset)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_file_collection: file_collection }} ->
        file_collection =
          file_collection
          |> preload(preloads[:path], preloads[:opts])
          |> FileCollection.put_file_urls()

        {:ok, file_collection}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def get_file_collection(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    FileCollection.Query.default()
    |> FileCollection.Query.for_account(account.id)
    |> Repo.get_by(fields)
    |> preload(preloads[:path], preloads[:opts])
    |> FileCollection.put_file_urls()
    |> FileCollection.put_file_count()
  end

  def update_file_collection(nil, _, _), do: {:error, :not_found}

  def update_file_collection(file_collection = %FileCollection{}, fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %{ file_collection | account: account }
      |> FileCollection.changeset(:update, fields, opts[:locale])

    with {:ok, file_collection} <- Repo.update(changeset) do
      file_collection =
        file_collection
        |> preload(preloads[:path], preloads[:opts])
        |> FileCollection.put_file_urls()

      {:ok, file_collection}
    else
      other -> other
    end
  end

  def update_file_collection(id, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    FileCollection
    |> Repo.get_by(id: id, account_id: account.id)
    |> update_file_collection(fields, opts)
  end

  def delete_file_collection(nil, _), do: {:error, :not_found}

  def delete_file_collection(file_collection = %FileCollection{}, opts) do
    account = get_account(opts)

    changeset =
      %{ file_collection | account: account }
      |> FileCollection.changeset(:delete)

    with {:ok, file_collection} <- Repo.delete(changeset) do
      {:ok, file_collection}
    else
      other -> other
    end
  end

  def delete_file_collection(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    FileCollection
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_file_collection(opts)
  end

  def delete_all_file_collection(opts = %{ account: account = %{ mode: "test" } }) do
    batch_size = opts[:batch_size] || 1000

    file_collection_ids =
      FileCollection.Query.default()
      |> FileCollection.Query.for_account(account.id)
      |> FileCollection.Query.paginate(size: batch_size, number: 1)
      |> FileCollection.Query.id_only()
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
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %FileCollectionMembership{ account_id: account.id, account: account }
      |> FileCollectionMembership.changeset(:insert, fields)

    case Repo.insert(changeset) do
      {:ok, fcm} ->
        fcm = preload(fcm, preloads[:path], preloads[:opts])
        {:ok, fcm}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_file_collection_membership(nil, _, _), do: {:error, :not_found}

  def update_file_collection_membership(fcm = %FileCollectionMembership{}, fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %{ fcm | account: account }
      |> FileCollectionMembership.changeset(:update, fields)

    with {:ok, fcm} <- Repo.update(changeset) do
      fcm = preload(fcm, preloads[:path], preloads[:opts])
      {:ok, fcm}
    else
      other -> other
    end
  end

  def update_file_collection_membership(id, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    FileCollectionMembership
    |> Repo.get_by(id: id, account_id: account.id)
    |> update_file_collection_membership(fields, opts)
  end

  def delete_file_collection_membership(nil, _), do: {:error, :not_found}

  def delete_file_collection_membership(fcm = %FileCollectionMembership{}, opts) do
    account = get_account(opts)

    changeset =
      %{ fcm | account: account }
      |> FileCollectionMembership.changeset(:delete)

    with {:ok, fcm} <- Repo.delete(changeset) do
      {:ok, fcm}
    else
      other -> other
    end
  end

  def delete_file_collection_membership(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    FileCollectionMembership
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_file_collection_membership(opts)
  end
end