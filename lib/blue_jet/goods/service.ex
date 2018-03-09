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
    filter = Map.take(fields, [:id, :code])

    Stockable.Query.default()
    |> Stockable.Query.for_account(account.id)
    |> Repo.get_by(filter)
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

  def create_unlockable(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %Unlockable{ account_id: account.id, account: account }
      |> Unlockable.changeset(:insert, fields)

    with {:ok, unlockable} <- Repo.insert(changeset) do
      unlockable = preload(unlockable, preloads[:path], preloads[:opts])
      {:ok, unlockable}
    else
      other -> other
    end
  end

  def get_unlockable(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)
    filter = Map.take(fields, [:id, :code])

    Unlockable.Query.default()
    |> Unlockable.Query.for_account(account.id)
    |> Repo.get_by(filter)
    |> preload(preloads[:path], preloads[:opts])
  end

  def update_unlockable(nil, _, _), do: {:error, :not_found}

  def update_unlockable(unlockable = %Unlockable{}, fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %{ unlockable | account: account }
      |> Unlockable.changeset(:update, fields, opts[:locale])

    with {:ok, unlockable} <- Repo.update(changeset) do
      unlockable = preload(unlockable, preloads[:path], preloads[:opts])
      {:ok, unlockable}
    else
      other -> other
    end
  end

  def update_unlockable(id, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Unlockable
    |> Repo.get_by(id: id, account_id: account.id)
    |> update_unlockable(fields, opts)
  end

  def delete_unlockable(nil, _), do: {:error, :not_found}

  def delete_unlockable(unlockable = %Unlockable{}, opts) do
    account = get_account(opts)

    changeset =
      %{ unlockable | account: account }
      |> Unlockable.changeset(:delete)

    with {:ok, unlockable} <- Repo.delete(changeset) do
      {:ok, unlockable}
    else
      other -> other
    end
  end

  def delete_unlockable(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Unlockable
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_unlockable(opts)
  end

  def delete_all_unlockable(opts = %{ account: account = %{ mode: "test" }})  do
    bulk_size = opts[:bulk_size] || 1000

    unlockable_ids =
      Unlockable.Query.default()
      |> Unlockable.Query.for_account(account.id)
      |> Unlockable.Query.paginate(size: bulk_size, number: 1)
      |> Unlockable.Query.id_only()
      |> Repo.all()

    Unlockable.Query.default()
    |> Unlockable.Query.filter_by(%{ id: unlockable_ids })
    |> Repo.delete_all()

    if length(unlockable_ids) === bulk_size do
      delete_all_unlockable(opts)
    else
      :ok
    end
  end

  #
  # MARK: Depositable
  #
  def list_depositable(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    Depositable.Query.default()
    |> Depositable.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Depositable.Query.filter_by(filter)
    |> Depositable.Query.for_account(account.id)
    |> Depositable.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_depositable(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    Depositable.Query.default()
    |> Depositable.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Depositable.Query.filter_by(filter)
    |> Depositable.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_depositable(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %Depositable{ account_id: account.id, account: account }
      |> Depositable.changeset(:insert, fields)

    with {:ok, depositable} <- Repo.insert(changeset) do
      depositable = preload(depositable, preloads[:path], preloads[:opts])
      {:ok, depositable}
    else
      other -> other
    end
  end

  def get_depositable(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)
    filter = Map.take(fields, [:id, :code])

    Depositable.Query.default()
    |> Depositable.Query.for_account(account.id)
    |> Repo.get_by(filter)
    |> preload(preloads[:path], preloads[:opts])
  end

  def update_depositable(nil, _, _), do: {:error, :not_found}

  def update_depositable(depositable = %Depositable{}, fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %{ depositable | account: account }
      |> Depositable.changeset(:update, fields, opts[:locale])

    with {:ok, depositable} <- Repo.update(changeset) do
      depositable = preload(depositable, preloads[:path], preloads[:opts])
      {:ok, depositable}
    else
      other -> other
    end
  end

  def update_depositable(id, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Depositable
    |> Repo.get_by(id: id, account_id: account.id)
    |> update_depositable(fields, opts)
  end

  def delete_depositable(nil, _), do: {:error, :not_found}

  def delete_depositable(depositable = %Depositable{}, opts) do
    account = get_account(opts)

    changeset =
      %{ depositable | account: account }
      |> Depositable.changeset(:delete)

    with {:ok, depositable} <- Repo.delete(changeset) do
      {:ok, depositable}
    else
      other -> other
    end
  end

  def delete_depositable(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Depositable
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_depositable(opts)
  end
end