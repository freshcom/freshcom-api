defmodule BlueJet.Balance.Service do
  use BlueJet, :service

  alias Ecto.Multi
  alias BlueJet.Balance.IdentityService
  alias BlueJet.Balance.{Card, Settings}

  defp get_account(opts) do
    opts[:account] || IdentityService.get_account(opts)
  end

  defp get_account_id(opts) do
    opts[:account_id] || get_account(opts).id
  end

  defp put_account(opts) do
    %{ opts | account: get_account(opts) }
  end

  def get_settings(opts) do
    account_id = get_account_id(opts)

    Repo.get_by(Settings, account_id: account_id)
  end

  def update_settings(nil, _, _), do: {:error, :not_found}

  def update_settings(settings, fields, opts) do
    account = get_account(opts)

    changeset =
      %{ settings | account: account }
      |> Settings.changeset(:update, fields)

    statements =
      Multi.new()
      |> Multi.update(:settings, changeset)
      |> Multi.run(:processed_settings, fn(%{ settings: settings }) ->
          Settings.process(settings, changeset)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_settings: settings }} ->
        {:ok, settings}

      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def update_settings(fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Settings
    |> Repo.get_by(account_id: account.id)
    |> update_settings(fields, opts)
  end

  def list_card(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    Card.Query.default()
    |> Card.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Card.Query.filter_by(filter)
    |> Card.Query.for_account(account.id)
    |> Card.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_card(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    Card.Query.default()
    |> Card.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Card.Query.filter_by(filter)
    |> Card.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def update_card(nil, _, _), do: {:error, :not_found}

  def update_card(card = %Card{}, fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %{ card | account: account }
      |> Card.changeset(:update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.update(:card, changeset)
      |> Multi.run(:processed_card, fn(%{ card: card }) ->
          Card.process(card, changeset)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_card: card }} ->
        card = preload(card, preloads[:path], preloads[:opts])
        {:ok, card}

      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def update_card(id, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Card
    |> Repo.get_by(id: id, account_id: account.id)
    |> update_card(fields, opts)
  end

  def delete_card(nil, _), do: {:error, :not_found}

  def delete_card(card = %Card{}, opts) do
    account = get_account(opts)

    changeset =
      %{ card | account: account }
      |> Card.changeset(:delete)

    statements =
      Multi.new()
      |> Multi.delete(:card, changeset)
      |> Multi.run(:processed_card, fn(%{ card: card }) ->
          Card.process(card, changeset)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_card: card }} ->
        {:ok, card}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def delete_card(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Card
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_card(opts)
  end
end