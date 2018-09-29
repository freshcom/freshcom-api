defmodule BlueJet.Balance.Card.Service do
  @moduledoc false

  use BlueJet, :service

  alias BlueJet.Balance.Card
  alias BlueJet.Balance.Card.{Query, Proxy}

  @spec list_card(map, map) :: [Card.t()]
  def list_card(query \\ %{}, opts), do: default_list(Query, query, opts)

  @spec count_card(map, map) :: integer
  def count_card(query \\ %{}, opts), do: default_count(Query, query, opts)

  @spec create_card(map, map) :: {:ok, Card.t()} | {:error, %{errors: keyword}}
  def create_card(fields, opts) do
    account = extract_account(opts)
    preload = extract_preload(opts)

    changeset =
      %Card{account_id: account.id, account: account}
      |> Card.changeset(:insert, fields)

    case do_create_or_update(changeset) do
      {:ok, card} ->
        {:ok, preload(card, preload[:paths], preload[:opts])}

      other ->
        other
    end
  end

  defp do_create_or_update(%{valid?: true, changes: changes} = changeset) do
    account = get_field(changeset, :account)
    existing_card =
      Repo.get_by(
        Card,
        account_id: account.id,
        owner_id: changes[:owner_id],
        owner_type: changes[:owner_type],
        fingerprint: changes[:fingerprint]
      )

    if existing_card do
      %{existing_card | account: account}
      |> change(changes)
      |> do_update_card()
    else
      do_create_card(changeset)
    end
  end

  defp do_create_or_update(changeset), do: {:error, changeset}

  defp do_update_card(changeset) do
    statements =
      Multi.new()
      |> Multi.update(:card, changeset)
      |> Multi.run(:stripe_card, &Proxy.sync_to_stripe_card(&1[:card]))

    case Repo.transaction(statements) do
      {:ok, %{card: card}} ->
        {:ok, card}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  defp do_create_card(changeset) do
    statements =
      Multi.new()
      |> Multi.insert(:card, changeset)
      |> Multi.run(:stripe_card, &Proxy.create_stripe_card(&1[:card], %{card_id: &1[:card].id, status: &1[:card].status}))

    case Repo.transaction(statements) do
      {:ok, %{card: card}} ->
        {:ok, card}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  @spec get_card(map, map) :: Card.t() | nil
  def get_card(identifiers, opts), do: default_get(Query, identifiers, opts)

  @spec update_card(nil, map, map) :: {:error, :not_found}
  def update_card(nil, _, _), do: {:error, :not_found}

  @spec update_card(Card.t(), map, map) :: {:ok, Card.t()} | {:error, %{errors: keyword}}
  def update_card(%Card{} = card, fields, opts) do
    account = extract_account(opts)
    preload = extract_preload(opts)

    changeset =
      %{card | account: account}
      |> Card.changeset(:update, fields, opts[:locale])

    case do_update_card(changeset) do
      {:ok, card} ->
        {:ok, preload(card, preload[:paths], preload[:opts])}

      other ->
        other
    end
  end

  @spec update_card(map, map, map) :: {:ok, Card.t()} | {:error, :not_found | %{errors: keyword}}
  def update_card(identifiers, fields, opts) do
    get_card(identifiers, Map.put(opts, :preload, %{}))
    |> update_card(fields, opts)
  end

  @spec delete_card(nil, map) :: {:error, :not_found}
  def delete_card(nil, _), do: {:error, :not_found}

  @spec delete_card(Card.t(), map) :: {:ok, Card.t()} | {:error, %{errors: keyword}}
  def delete_card(%Card{} = card, opts) do
    account = extract_account(opts)

    changeset =
      %{card | account: account}
      |> Card.changeset(:delete)

    statements =
      Multi.new()
      |> Multi.delete(:card, changeset)
      |> Multi.run(:primary_card, &set_new_primary(&1[:card]))
      |> Multi.run(:stripe_card, &Proxy.delete_stripe_card(&1[:card]))

    case Repo.transaction(statements) do
      {:ok, %{card: card}} ->
        {:ok, card}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  @spec delete_card(map, map) :: {:ok, Card.t()} | {:error, :not_found | %{errors: keyword}}
  def delete_card(identifiers, opts) do
    Card
    |> get(identifiers, Map.merge(opts, %{preloads: %{}}))
    |> delete_card(opts)
  end

  defp set_new_primary(%{primary: true} = card) do
    filter = %{
      status: "saved_by_owner",
      owner_type: card.owner_type,
      owner_id: card.owner_id,
      primary: false
    }

    new_primary_card =
      Query.default()
      |> for_account(card.account_id)
      |> except(id: card.id)
      |> Query.filter_by(filter)
      |> sort_by(desc: :inserted_at)
      |> Repo.one()
      |> set_as_primary()

    {:ok, new_primary_card}
  end

  defp set_new_primary(card = %{primary: false}), do: {:ok, card}

  @spec set_as_primary(Card.t()) :: Card.t()
  def set_as_primary(%{status: "saved_by_owner"} = card) do
    Query.default()
    |> for_account(card.account_id)
    |> Query.filter_by(%{owner_type: card.owner_type, owner_id: card.owner_id})
    |> Repo.update_all(set: [primary: false])

    card =
      card
      |> change(%{primary: true})
      |> Repo.update!()

    card
  end

  def set_as_primary(nil), do: nil

  @spec delete_all_card(map) :: :ok
  def delete_all_card(opts) do
    delete_all(Card, opts)
  end
end