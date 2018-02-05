defmodule BlueJet.Goods.Service do
  use BlueJet, :service

  alias BlueJet.Goods.{Stockable, Unlockable, Depositable}
  alias BlueJet.Goods.{IdentityService}

  defp get_account(opts) do
    opts[:account] || IdentityService.get_account(opts)
  end

  def get_stockable(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    Stockable.Query.default()
    |> Stockable.Query.for_account(account.id)
    |> Repo.get_by(fields)
    |> preload(preloads[:path], preloads[:opts])
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

  # def get_unlockable(id) do
  #   Repo.get(Unlockable, id)
  # end

  # def get_unlockable(id, opts) do
  #   account_id = opts[:account_id] || opts[:account].id
  #   Repo.get_by(Unlockable, id: id, account_id: account_id)
  # end

  # def get_unlockable_by_code(code, opts) do
  #   account_id = opts[:account_id] || opts[:account].id
  #   Repo.get_by(Unlockable, code: code, account_id: account_id)
  # end

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