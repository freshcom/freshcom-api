defmodule BlueJet.Identity.Service do
  use BlueJet.EventEmitter, namespace: :identity

  alias BlueJet.Repo
  alias BlueJet.Identity.Account
  alias BlueJet.Identity.User
  alias BlueJet.Identity.AccountMembership
  alias BlueJet.Identity.RefreshToken

  alias Ecto.Multi
  alias Ecto.Changeset

  def get_account(%{ account_id: nil }), do: nil
  def get_account(%{ account_id: account_id, account: nil }), do: get_account(account_id)
  def get_account(%{ account: account }), do: account
  def get_account(id), do: Repo.get!(Account, id)

  def create_account(fields) do
    changeset =
      %Account{ mode: "live" }
      |> Account.changeset(fields)

    statements =
      Multi.new()
        |> Multi.insert(:account, changeset)
        |> Multi.run(:test_account, fn(%{ account: account }) ->
            changeset = Account.changeset(%Account{ live_account_id: account.id, mode: "test" }, fields)
            Repo.insert(changeset)
           end)
        |> Multi.run(:prt_live, fn(%{ account: account }) ->
            prt_live = Repo.insert!(%RefreshToken{ account_id: account.id })
            {:ok, prt_live}
           end)
        |> Multi.run(:prt_test, fn(%{ test_account: test_account }) ->
            prt_test = Repo.insert!(%RefreshToken{ account_id: test_account.id })
            {:ok, prt_test}
           end)
        |> Multi.run(:after_account_create, fn(%{ account: account, test_account: test_account }) ->
            emit_event("identity.account.after_create", %{ account: account, test_account: test_account })
           end)

    case Repo.transaction(statements) do
      {:ok, %{ account: account, test_account: test_account }} ->
        account = %{ account | test_account_id: test_account.id }
        {:ok, account}

      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def create_user(fields, %{ account: nil }), do: create_user(fields, %{ account_id: nil })
  def create_user(fields, %{ account: account }), do: create_user(fields, %{ account_id: account.id })

  def create_user(fields, opts = %{ account_id: nil }) when map_size(opts) == 1 do
    account_fields =
      fields
      |> Map.take(["default_locale"])
      |> Map.put("name", fields["account_name"])

    statements =
      Multi.new()
      |> Multi.run(:account, fn(_) ->
          create_account(account_fields)
         end)
      |> Multi.run(:user, fn(%{ account: account }) ->
          changeset = User.changeset(%User{ default_account_id: account.id }, fields)
          Repo.insert(changeset)
         end)
      |> Multi.run(:account_membership, fn(%{ account: account, user: user }) ->
          account_membership = Repo.insert!(%AccountMembership{
            account_id: account.id,
            user_id: user.id,
            role: "administrator"
          })

          {:ok, account_membership}
         end)
      |> Multi.run(:urt_live, fn(%{ account: account, user: user}) ->
          refresh_token = Repo.insert!(%RefreshToken{ account_id: account.id, user_id: user.id })
          {:ok, refresh_token}
         end)
      |> Multi.run(:urt_test, fn(%{ account: account, user: user}) ->
          refresh_token = Repo.insert!(%RefreshToken{ account_id: account.test_account_id, user_id: user.id })
          {:ok, refresh_token}
         end)

    case Repo.transaction(statements) do
      {:ok, %{ user: user, account: account }} ->
        user = %{ user | default_account: account }
        {:ok, user}

      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def create_user(fields, opts = %{ account_id: account_id }) when map_size(opts) == 1 do
    test_account = Repo.get_by(Account, mode: "test", live_account_id: account_id)

    live_account_id = if test_account do
      account_id
    else
      nil
    end
    test_account_id = if test_account do
      test_account.id
    else
      account_id
    end

    user = %User{ default_account_id: account_id, account_id: account_id }
    changeset = User.changeset(user, fields)

    statements =
      Multi.new()
      |> Multi.insert(:user, changeset)
      |> Multi.run(:account_membership, fn(%{ user: user }) ->
          Repo.insert(%AccountMembership{
            account_id: account_id,
            user_id: user.id,
            role: Map.get(fields, "role")
          })
         end)
      |> Multi.run(:urt_live, fn(%{ user: user }) ->
          if live_account_id do
            refresh_token = Repo.insert!(%RefreshToken{ account_id: live_account_id, user_id: user.id })
            {:ok, refresh_token}
          else
            {:ok, nil}
          end
         end)
      |> Multi.run(:urt_test, fn(%{ user: user }) ->
          if test_account_id do
            refresh_token = Repo.insert!(%RefreshToken{ account_id: test_account_id, user_id: user.id })
            {:ok, refresh_token}
          else
            {:ok, nil}
          end
         end)
      |> Multi.run(:after_create, fn(%{ user: user }) ->
          emit_event("identity.user.after_create", %{ user: user })
         end)

    case Repo.transaction(statements) do
      {:ok, %{ user: user }} -> {:ok, user}
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def create_password_reset_token(email, opts) do
    changeset =
      Changeset.change(%User{}, %{ email: email })
      |> Changeset.validate_required(:email)
      |> Changeset.validate_format(:email, Application.get_env(:blue_jet, :email_regex))

    with true <- changeset.valid?,
         user = %User{} <- get_user_by_email(email, opts)
    do
      user = User.refresh_password_reset_token(user)
      event_data = Map.merge(opts, %{ user: user, email: email })
      emit_event("identity.password_reset_token.after_create", event_data)

      {:ok, user}
    else
      false ->
        {:error, changeset}

      nil ->
        event_data = Map.merge(opts, %{ user: nil, email: email })
        emit_event("identity.password_reset_token.not_created", event_data)
        {:ok, nil}
    end
  end

  def create_password(user = %{}, new_password) do
    changeset =
      Changeset.change(%User{}, %{ password: new_password })
      |> Changeset.validate_required(:password)
      |> Changeset.validate_length(:password, min: 8)

    if changeset.valid? do
      user =
        user
        |> User.refresh_password_reset_token()
        |> User.update_password(new_password)

      {:ok, user}
    else
      {:error, changeset}
    end
  end

  def create_password(nil, _, _), do: {:error, :not_found}

  def create_password(password_reset_token, new_password, opts = %{ account: nil }) when map_size(opts) == 1 do
    user =
      User.Query.default()
      |> User.Query.global()
      |> Repo.get_by(password_reset_token: password_reset_token)

    if user do
      create_password(user, new_password)
    else
      {:error, :not_found}
    end
  end

  def create_password(password_reset_token, new_password, opts = %{ account: account }) when map_size(opts) == 1 do
    user =
      User.Query.default()
      |> User.Query.for_account(account.id)
      |> Repo.get_by(password_reset_token: password_reset_token)

    if user do
      create_password(user, new_password)
    else
      {:error, :not_found}
    end
  end

  defp get_user_by_email(email, opts = %{ account: nil }) when map_size(opts) == 1 do
    get_user_by_email(email, %{})
  end

  defp get_user_by_email(email, opts) when map_size(opts) == 0 do
    User.Query.default()
    |> User.Query.global()
    |> Repo.get_by(email: email)
  end

  defp get_user_by_email(email, opts) do
    account_id = opts[:account_id] || opts[:account].id

    User.Query.default()
    |> User.Query.for_account(account_id)
    |> Repo.get_by(email: email)
  end
end