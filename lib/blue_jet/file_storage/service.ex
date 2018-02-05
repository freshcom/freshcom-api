defmodule BlueJet.FileStorage.Service do
  use BlueJet, :service

  alias BlueJet.FileStorage.IdentityService
  alias BlueJet.FileStorage.{File, FileCollection}

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
      file = preload(file, preloads[:path], preloads[:opts])
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
      file = preload(file, preloads[:path], preloads[:opts])
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

  # def delete_file(file = %{}) do
  #   file
  #   |> File.delete_object()
  #   |> Repo.delete!()
  # end

  # def delete_file(id, opts) do
  #   account_id = opts[:account_id] || opts[:account].id

  #   file =
  #     File.Query.default()
  #     |> File.Query.for_account(account_id)
  #     |> Repo.get(File, id)

  #   if file do
  #     delete_file(file)
  #   else
  #     {:error, :not_found}
  #   end
  # end
end