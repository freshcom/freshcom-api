defmodule BlueJet.Notification.Service do

  use BlueJet, :service

  alias BlueJet.Notification.IdentityService

  defp get_account(opts) do
    opts[:account] || IdentityService.get_account(opts)
  end

  #
  # MARK: Trigger
  #
  def list_trigger(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    Trigger.Query.default()
    |> Trigger.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Trigger.Query.filter_by(filter)
    |> Trigger.Query.for_account(account.id)
    |> Trigger.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_trigger(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    Trigger.Query.default()
    |> Trigger.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Trigger.Query.filter_by(filter)
    |> Trigger.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def create_trigger(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %Trigger{ account_id: account.id, account: account }
      |> Trigger.changeset(:insert, fields)

    with {:ok, trigger} <- Repo.insert(changeset) do
      trigger = preload(trigger, preloads[:path], preloads[:opts])
      {:ok, trigger}
    else
      other -> other
    end
  end

  def get_trigger(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    Trigger.Query.default()
    |> Trigger.Query.for_account(account.id)
    |> Repo.get_by(fields)
    |> preload(preloads[:path], preloads[:opts])
  end

  def delete_trigger(nil, _), do: {:error, :not_found}

  def delete_trigger(trigger = %Trigger{}, opts) do
    account = get_account(opts)

    changeset =
      %{ trigger | account: account }
      |> Trigger.changeset(:delete)

    with {:ok, trigger} <- Repo.delete(changeset) do
      {:ok, trigger}
    else
      other -> other
    end
  end

  def delete_trigger(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Trigger
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_trigger(opts)
  end
end