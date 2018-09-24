defmodule BlueJet.Identity.AccountMembership.Service do
  @moduledoc false

  use BlueJet, :service

  import BlueJet.Utils, only: [atomize_keys: 2]

  alias BlueJet.Identity.AccountMembership

  @spec list_account_membership(map, map) :: [AccountMembership.t()]
  def list_account_membership(query, opts \\ %{}) do
    pagination = extract_pagination(opts)
    preload = extract_preload(opts)
    filter = extract_account_membership_filter(query, opts)

    AccountMembership.Query.default()
    |> AccountMembership.Query.search(query[:search])
    |> AccountMembership.Query.filter_by(filter)
    |> sort_by(desc: :inserted_at)
    |> paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preload[:paths], preload[:opts])
  end

  @spec count_account_membership(map, map) :: integer
  def count_account_membership(query, opts \\ %{}) do
    filter = extract_account_membership_filter(query, opts)

    AccountMembership.Query.default()
    |> AccountMembership.Query.filter_by(filter)
    |> Repo.aggregate(:count, :id)
  end

  defp extract_account_membership_filter(query, opts) do
    filter = atomize_keys(query[:filter], AccountMembership.Query.filterable_fields())

    unless opts[:account] || filter[:user_id] do
      raise ArgumentError, message: "when account is not provided in opts :user_id must be provided as filter"
    end

    if filter[:user_id] do
      filter
    else
      Map.put(filter, :account_id, opts[:account].id)
    end
  end

  @spec create_account_membership!(map, map) :: AccountMembership.t()
  def create_account_membership!(fields, opts) do
    account = extract_account(opts)

    %AccountMembership{account_id: account.id, account: account}
    |> AccountMembership.changeset(:insert, fields)
    |> Repo.insert!()
  end

  @spec get_account_membership(map, map) :: AccountMembership.t() | nil
  def get_account_membership(identifiers, opts),
    do: default_get(AccountMembership.Query, identifiers, opts)

  @spec update_account_membership(map, map, map) :: {:ok, AccountMembership.t()} | {:error, %{errors: Keyword.t()}}
  def update_account_membership(identifiers, fields, opts),
    do: default_update(identifiers, fields, opts, &get_account_membership/2)
end