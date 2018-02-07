defmodule BlueJet.Goods.Service do
  use BlueJet, :service

  alias BlueJet.Goods.{Stockable, Unlockable, Depositable}
  alias BlueJet.Goods.{IdentityService}

  defp get_account(opts) do
    opts[:account] || IdentityService.get_account(opts)
  end

  defp put_account(opts) do
    %{ opts | account: get_account(opts) }
  end

  def list_stockable(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    Stockable.Query.default()
    |> Stockable.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Stockable.Query.filter_by(filter)
    |> Stockable.Query.for_account(account.id)
    |> Stockable.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_stockable(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    Stockable.Query.default()
    |> Stockable.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Stockable.Query.filter_by(filter)
    |> Stockable.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_stockable(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %Stockable{ account_id: account.id, account: account }
      |> Stockable.changeset(:insert, fields)

    with {:ok, stockable} <- Repo.insert(changeset) do
      stockable = preload(stockable, preloads[:path], preloads[:opts])
      {:ok, stockable}
    else
      other -> other
    end
  end

  def get_stockable(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    Stockable.Query.default()
    |> Stockable.Query.for_account(account.id)
    |> Repo.get_by(fields)
    |> preload(preloads[:path], preloads[:opts])
  end

  def update_stockable(nil, _, _), do: {:error, :not_found}

  def update_stockable(stockable = %Stockable{}, fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %{ stockable | account: account }
      |> Stockable.changeset(:update, fields, opts[:locale])

    with {:ok, stockable} <- Repo.update(changeset) do
      stockable = preload(stockable, preloads[:path], preloads[:opts])
      {:ok, stockable}
    else
      other -> other
    end
  end

  def update_stockable(id, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Stockable
    |> Repo.get_by(id: id, account_id: account.id)
    |> update_stockable(fields, opts)
  end

  def delete_stockable(nil, _), do: {:error, :not_found}

  def delete_stockable(stockable = %Stockable{}, opts) do
    account = get_account(opts)

    changeset =
      %{ stockable | account: account }
      |> Stockable.changeset(:delete)

    with {:ok, stockable} <- Repo.delete(changeset) do
      {:ok, stockable}
    else
      other -> other
    end
  end

  def delete_stockable(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Stockable
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_stockable(opts)
  end

  #
  # MARK: Unlockable
  #
  def list_unlockable(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    Unlockable.Query.default()
    |> Unlockable.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Unlockable.Query.filter_by(filter)
    |> Unlockable.Query.for_account(account.id)
    |> Unlockable.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_unlockable(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    Unlockable.Query.default()
    |> Unlockable.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Unlockable.Query.filter_by(filter)
    |> Unlockable.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def get_unlockable(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    Unlockable.Query.default()
    |> Unlockable.Query.for_account(account.id)
    |> Repo.get_by(fields)
    |> preload(preloads[:path], preloads[:opts])
  end

  def get_depositable(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    Depositable.Query.default()
    |> Depositable.Query.for_account(account.id)
    |> Repo.get_by(fields)
    |> preload(preloads[:path], preloads[:opts])
  end

  def create_unlockable(fields, opts) do
    account_id = opts[:account_id] || opts[:account].id

    %Unlockable{ account_id: account_id, account: opts[:account] }
    |> Unlockable.changeset(fields)
    |> Repo.insert()
  end

  def update_unlockable(id, fields, opts) do
    account_id = opts[:account_id] || opts[:account].id
    unlockable =
      Unlockable.Query.default()
      |> Unlockable.Query.for_account(account_id)
      |> Repo.get(id)

    if unlockable do
      unlockable
      |> Map.put(:account, opts[:account])
      |> Unlockable.changeset(fields, opts[:locale])
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end
end