defmodule BlueJet.Identity.User.Service do
  use BlueJet, :service

  import BlueJet.Utils, only: [atomize_keys: 2]

  import BlueJet.Identity.Account.Service, only: [create_account: 2]
  import BlueJet.Identity.AccountMembership.Service, only: [create_account_membership!: 2]
  import BlueJet.Identity.RefreshToken.Service, only: [create_refresh_token!: 2]

  alias BlueJet.Identity.{
    Account,
    User,
    AccountMembership,
    PhoneVerificationCode
  }

  #
  # MARK: User
  #
  @spec create_user(map, map) :: {:ok, User.t()} | {:error, %{errors: Keyword.t()}}
  def create_user(fields, %{account: nil} = opts) do
    account_fields =
      fields
      |> Map.take(["default_locale"])
      |> Map.merge(%{"name" => "Unnamed Account"})
    create_opts = Map.take(opts, [:bypass_pvc_validation])

    statements =
      Multi.new()
      |> Multi.run(:account, fn(_) -> create_account(account_fields, %{skip_dispatch: true}) end)
      |> Multi.run(:user, &do_create_user(%{default_account: &1[:account]}, fields, create_opts))
      |> Multi.run(:account_membership, &do_create_account_membership!(&1, %{role: "administrator", is_owner: true}))
      |> Multi.run(:urt_live, &do_create_refresh_token!(&1))
      |> Multi.run(:urt_test, &do_create_refresh_token!(%{account: &1[:account].test_account, user: &1[:user]}))
      |> Multi.run(:dispatch1, &dispatch("identity:account.create.success", Map.take(&1, [:account]), skip: opts[:skip_dispatch]))
      |> Multi.run(:dispatch2, &dispatch("identity:user.create.success", Map.take(&1, [:user, :account]), skip: opts[:skip_dispatch]))
      |> Multi.run(:dispatch3, &dispatch("identity:email_verification_token.create.success", Map.take(&1, [:user]), skip: opts[:skip_dispatch]))

    case Repo.transaction(statements) do
      {:ok, %{user: user, account: account}} ->
        {:ok, %{user | default_account: account}}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def create_user(fields, %{account: account} = opts) do
    role = fields["role"] || fields[:role]
    create_opts = Map.take(opts, [:bypass_pvc_validation])

    statements =
      Multi.new()
      |> Multi.run(:user, fn(_) -> do_create_user(%{account: account}, fields, create_opts) end)
      |> Multi.run(:account_membership, &do_create_account_membership!(Map.merge(opts, &1), %{role: role}))
      |> Multi.run(:urt_1, &do_create_refresh_token!(%{user: &1[:user], account: account}))
      |> Multi.run(:urt_2, fn(%{user: user}) ->
        if account.mode == "live" do
          test_account = Repo.get_by!(Account, mode: "test", live_account_id: account.id)
          do_create_refresh_token!(%{account: test_account, user: user})
        else
          {:ok, nil}
        end
      end)
      |> Multi.run(:delete_all_pvc, &do_delete_all_pvc(&1))
      |> Multi.run(:dispatch1, &dispatch("identity:user.create.success", %{user: &1[:user], account: account}, skip: opts[:skip_dispatch]))
      |> Multi.run(:dispatch2, fn(%{user: user}) ->
        if user.email do
          dispatch("identity:email_verification_token.create.success", %{user: user}, skip: opts[:skip_dispatch])
        else
          {:ok, nil}
        end
      end)

    case Repo.transaction(statements) do
      {:ok, %{user: user, account_membership: am}} ->
        {:ok, %{user | role: am.role, default_account: account, account: account}}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  defp do_create_user(data, fields, opts) do
    default_account_id = (data[:default_account] || %Account{}).id
    account_id = (data[:account] || %Account{}).id

    %User{default_account_id: default_account_id || account_id, account_id: account_id}
    |> User.changeset(:insert, fields, opts)
    |> Repo.insert()
  end

  defp do_create_account_membership!(data, fields) do
    account_membership =
      fields
      |> Map.merge(%{user_id: data.user.id})
      |> create_account_membership!(%{account: data.account})

    {:ok, account_membership}
  end

  defp do_create_refresh_token!(data) do
    user_id = (data[:user] || %User{}).id
    refresh_token = create_refresh_token!(%{user_id: user_id}, %{account: data.account})

    {:ok, refresh_token}
  end

  defp do_delete_all_pvc(%{user: user}) do
    PhoneVerificationCode.Query.default()
    |> PhoneVerificationCode.Query.filter_by(%{phone_number: user.phone_number})
    |> Repo.delete_all()

    {:ok, user}
  end

  @spec get_user(map, map) :: User.t() | nil
  def get_user(identifiers, opts) do
    account = extract_account(opts)
    identifiers = atomize_keys(identifiers, User.Query.identifiable_fields())

    do_get_user(identifiers, opts)
    |> put_account(account)
  end

  defp do_get_user(identifiers, %{type: :managed, account: account}) when not is_nil(account) do
    User.Query.default()
    |> for_account(account.id)
    |> User.Query.get_by(identifiers)
    |> Repo.one()
    |> User.put_role(account.id)
  end

  defp do_get_user(identifiers, %{account: account}) when not is_nil(account) do
    user =
      User.Query.default()
      |> User.Query.member_of_account(account.id)
      |> User.Query.get_by(identifiers)
      |> Repo.one()
      |> User.put_role(account.id)

    if !user && account.mode == "test" do
      do_get_user(identifiers, %{account: %Account{id: account.live_account_id}})
    else
      user
    end
  end

  defp do_get_user(identifiers, _) do
    User.Query.default()
    |> User.Query.standard()
    |> User.Query.get_by(identifiers)
    |> Repo.one()
  end

  @spec update_user(map, map, map) :: {:ok, User.t()} | {:error, %{errors: Keyword.t()}}
  def update_user(%User{} = user, fields, opts) do
    account = extract_account(opts)

    changeset = User.changeset(user, :update, fields)
    am = Repo.get_by(AccountMembership, account_id: account.id, user_id: user.id)

    statements =
      Multi.new()
      |> Multi.run(:user, fn(_) -> do_update_user(user, fields) end)
      |> Multi.run(:account_membership, fn(_) -> do_update_account_membership(am, fields) end)
      |> Multi.run(:delete_all_pvc, &do_delete_all_pvc(&1))
      |> Multi.run(:dispatch1, fn(_) ->
        dispatch("identity:user.update.success", %{changeset: changeset, account: account}, skip: opts[:skip_dispatch])
      end)
      |> Multi.run(:dispatch2, fn(%{user: user}) ->
        if changeset.changes[:email_verification_token] do
          dispatch("identity:email_verification_token.create.success", %{user: user}, skip: opts[:skip_dispatch])
        else
          {:ok, nil}
        end
      end)

    case Repo.transaction(statements) do
      {:ok, %{user: user}} ->
        {:ok, user}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_user(nil, _, _), do: {:error, :not_found}

  def update_user(identifiers, fields, opts) do
    account = extract_account(opts)

    user = get_user(identifiers, opts)
    if account.mode == "test" && user && user.account_id != account.id do
      {:error, :unprocessable_for_live_user}
    else
      update_user(user, fields, opts)
    end
  end

  defp do_update_user(user, fields) do
    user
    |> User.changeset(:update, fields)
    |> Repo.update()
  end

  defp do_update_account_membership(account_membership, fields) do
    account_membership
    |> AccountMembership.changeset(:update, fields)
    |> Repo.update()
  end

  @spec delete_user(map, map) :: {:ok, User.t()} | {:error, %{errors: Keyword.t()}}
  def delete_user(identifiers, opts),
    do: default_delete(identifiers, Map.put(opts, :type, :managed), &get_user/2)
end
