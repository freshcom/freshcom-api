defmodule BlueJet.Identity.Account.Service do
  use BlueJet, :service

  import Ecto.Changeset
  import BlueJet.Identity.AccountMembership.Service, only: [create_account_membership!: 2]
  import BlueJet.Identity.RefreshToken.Service, only: [create_refresh_token!: 2]

  alias BlueJet.Identity.{
    Account,
    AccountMembership,
    User,
    PhoneVerificationCode
  }

  @spec get_account(map) :: Account.t() | nil
  def get_account(%{id: id}) do
    Repo.get(Account, id)
    |> Account.put_test_account_id()
  end

  @spec create_account(map, map) :: {:ok, Account.t()} | {:error, %{errors: Keyword.t()}}
  def create_account(fields, opts \\ %{}) do
    if opts[:user] && User.type(opts[:user]) == :managed do
      raise ArgumentError, message: "managed user cannot be used to create account"
    end

    statements =
      Multi.new()
      |> Multi.run(:account, fn(_) -> create_live_account(fields) end)
      |> Multi.run(:test_account, &create_test_account(&1, fields))
      |> Multi.run(:dispatch, &dispatch("identity:account.create.success", &1))
      |> Multi.run(:account_membership, fn(%{account: account}) ->
        if opts[:user] do
          do_create_account_membership!(%{account: account, user: opts[:user]}, %{is_owner: true, role: "administrator"})
        else
          {:ok, nil}
        end
      end)

    case Repo.transaction(statements) do
      {:ok, %{account: account, test_account: test_account}} ->
        account = %{account | test_account: test_account, test_account_id: test_account.id}
        {:ok, account}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  defp create_live_account(fields) do
    %Account{mode: "live"}
    |> do_create_account(fields)
  end

  defp create_test_account(data, fields) do
    %Account{live_account_id: data.account.id, mode: "test"}
    |> do_create_account(fields)
  end

  defp do_create_account(%Account{} = account, fields) do
    changeset = Account.changeset(account, :insert, fields)

    statements =
      Multi.new()
      |> Multi.insert(:account, changeset)
      |> Multi.run(:prt, &do_create_refresh_token!(&1))

    case Repo.transaction(statements) do
      {:ok, %{account: account}} ->
        {:ok, account}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  defp do_create_refresh_token!(data) do
    user_id = (data[:user] || %User{}).id
    refresh_token = create_refresh_token!(%{user_id: user_id}, %{account: data.account})

    {:ok, refresh_token}
  end

  defp do_create_account_membership!(data, fields) do
    account_membership =
      fields
      |> Map.merge(%{user_id: data.user.id})
      |> create_account_membership!(%{account: data.account})

    {:ok, account_membership}
  end

  @spec update_account(Account.t(), map, map) :: {:ok, Account.t()} | {:error, %{errors: Keyword.t()}}
  def update_account(account, fields, opts \\ %{})

  def update_account(%Account{mode: "test"}, _, _) do
    {:error, :unprocessable_for_test_account}
  end

  def update_account(%Account{} = account, fields, opts) do
    changeset = Account.changeset(account, :update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.update(:_1, changeset)
      |> Multi.run(:account, &sync_to_test_account!(&1[:_1], changeset))

    case Repo.transaction(statements) do
      {:ok, %{account: account}} ->
        {:ok, account}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  defp sync_to_test_account!(%Account{mode: "live"} = account, %{action: :update} = changeset) do
    test_account =
      Account
      |> Repo.get_by(live_account_id: account.id)
      |> change(changeset.changes)
      |> Repo.update!()

    {:ok, %{account | test_account: test_account, test_account_id: test_account.id}}
  end

  def sync_to_test_account(account, _), do: {:ok, account}

  @spec reset_account(Account.t()) :: {:ok, Account.t()}
  def reset_account(%Account{mode: "test"} = account) do
    statements =
      Multi.new()
      |> Multi.delete_all(:_1, for_account(AccountMembership, account.id))
      |> Multi.delete_all(:_2, for_account(User, account.id))
      |> Multi.delete_all(:_3, for_account(PhoneVerificationCode, account.id))
      |> Multi.run(:dispatch, fn(_) ->
        dispatch("identity:account.reset.success", %{account: account})
      end)

    {:ok, _} = Repo.transaction(statements)
    {:ok, account}
  end
end