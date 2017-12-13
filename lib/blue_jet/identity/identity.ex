defmodule BlueJet.Identity do
  use BlueJet, :context

  alias Ecto.Changeset
  alias BlueJet.Identity.Authorization
  alias BlueJet.Identity.Authentication
  alias BlueJet.Identity.User
  alias BlueJet.Identity.RefreshToken
  alias BlueJet.Identity.AccountMembership
  alias BlueJet.Identity.Account

  defmodule Query do
    alias Ecto.Multi
    alias BlueJet.Identity

    def create_account(fields) do
      Multi.new()
      |> Multi.insert(:account, Account.changeset(%Account{ mode: "live" }, fields))
      |> Multi.run(:test_account, fn(%{ account: account }) ->
          changeset = Account.changeset(%Account{ live_account_id: account.id, mode: "test" }, fields)
          Repo.insert(changeset)
        end)
      |> Multi.run(:prt_live, fn(%{ account: account }) ->
          prt_live = Repo.insert!(RefreshToken.changeset(%RefreshToken{}, %{ account_id: account.id }))
          {:ok, prt_live}
         end)
      |> Multi.run(:prt_test, fn(%{ test_account: test_account }) ->
          prt_test = Repo.insert!(RefreshToken.changeset(%RefreshToken{}, %{ account_id: test_account.id }))
          {:ok, prt_test}
         end)
      |> Multi.run(:after_account_create, fn(%{ account: account, test_account: test_account }) ->
          Identity.run_event_handler("identity.account.created", %{ account: account, test_account: test_account })
         end)
    end

    def create_global_user(fields) do
      Multi.new()
      |> Multi.append(create_account(%{ name: fields.account_name, default_locale: fields.default_locale }))
      |> Multi.run(:user, fn(%{ account: account }) ->
          Repo.insert(User.changeset(%User{}, Map.merge(fields, %{ default_account_id: account.id })))
        end)
      |> Multi.run(:account_membership, fn(%{ account: account, user: user }) ->
          account_membership = Repo.insert!(
            AccountMembership.changeset(%AccountMembership{}, %{
              account_id: account.id,
              user_id: user.id,
              role: "administrator"
            })
          )

          {:ok, account_membership}
        end)
      |> Multi.run(:urt_live, fn(%{ account: account, user: user}) ->
          refresh_token = Repo.insert!(RefreshToken.changeset(%RefreshToken{}, %{ account_id: account.id, user_id: user.id }))
          {:ok, refresh_token}
        end)
      |> Multi.run(:urt_test, fn(%{ test_account: test_account, user: user}) ->
          refresh_token = Repo.insert!(RefreshToken.changeset(%RefreshToken{}, %{ account_id: test_account.id, user_id: user.id }))
          {:ok, refresh_token}
        end)
    end

    def create_account_user(account_id, fields) do
      test_account = Repo.get_by!(Account, mode: "test", live_account_id: account_id)

      Multi.new()
      |> Multi.insert(:user, User.changeset(%User{}, Map.merge(fields, %{ "default_account_id" => account_id, "account_id" => account_id })))
      |> Multi.run(:account_membership, fn(%{ user: user }) ->
          account_membership = Repo.insert!(
            AccountMembership.changeset(%AccountMembership{}, %{
              account_id: account_id,
              user_id: user.id,
              role: Map.get(fields, "role")
            })
          )

          {:ok, account_membership}
        end)
      |> Multi.run(:urt_live, fn(%{ user: user }) ->
          refresh_token = Repo.insert!(RefreshToken.changeset(%RefreshToken{}, %{ account_id: account_id, user_id: user.id }))
          {:ok, refresh_token}
        end)
      |> Multi.run(:urt_test, fn(%{ user: user }) ->
          refresh_token = Repo.insert!(RefreshToken.changeset(%RefreshToken{}, %{ account_id: test_account.id, user_id: user.id }))
          {:ok, refresh_token}
        end)
    end
  end

  def run_event_handler(name, data) do
    listeners = Map.get(Application.get_env(:blue_jet, :identity, %{}), :listeners, [])

    Enum.reduce_while(listeners, {:ok, []}, fn(listener, acc) ->
      with {:ok, result} <- listener.handle_event(name, data) do
        {:ok, acc_result} = acc
        {:cont, {:ok, acc_result ++ [{listener, result}]}}
      else
        {:error, errors} -> {:halt, {:error, errors}}
        other -> {:halt, other}
      end
    end)
  end

  def authorize(vas = %{}, endpoint) do
    Authorization.authorize(vas, endpoint)
  end

  def create_token(%AccessRequest{ fields: fields }) do
    with {:ok, token} <- Authentication.create_token(fields) do
      {:ok, %AccessResponse{ data: token }}
    else
      {:error, errors} -> {:error, %AccessResponse{ errors: errors }}
    end
  end

  ####
  # Account
  ####
  def list_account(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- authorize(vas, "identity.list_account") do
      do_list_account(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_list_account(%AccessRequest{ vas: %{ user_id: user_id }, locale: locale }) do
    accounts =
      Account
      |> Account.Query.has_member(user_id)
      |> Repo.all()
      |> Translation.translate(locale)

    {:ok, %AccessResponse{ data: accounts }}
  end

  def get_account(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- authorize(vas, "identity.get_account") do
      do_get_account(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_get_account(request = %AccessRequest{ vas: %{ account_id: account_id }, locale: locale }) do
    account =
      Account
      |> Repo.get!(account_id)
      |> Account.put_test_account_id()
      |> Translation.translate(locale)

    {:ok, %AccessResponse{ data: account }}
  end

  def update_account(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- authorize(vas, "identity.update_account") do
      do_update_account(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_update_account(request = %AccessRequest{ vas: %{ account_id: account_id }, fields: fields }) do
    changeset =
      Account
      |> Repo.get!(account_id)
      |> Account.changeset(fields)

    with {:ok, account} <- Repo.update(changeset) do
      {:ok, %AccessResponse{ data: account }}
    else
      {:error, changeset} -> {:error, %AccessResponse{ errors: changeset.errors }}
    end
  end

  ####
  # User
  ####
  def create_user(request = %AccessRequest{ vas: vas, fields: fields, preloads: preloads }) do
    with {:ok, role} <- authorize(vas, "identity.create_user") do
      do_create_user(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  defp do_create_user(request = %AccessRequest{ vas: vas, fields: fields, preloads: preloads }) when map_size(vas) == 0 do
    result = Query.create_global_user(fields) |> Repo.transaction()
    do_create_user_response(result, preloads)
  end
  defp do_create_user(request = %{ vas: %{ account_id: account_id, user_id: user_id }, fields: fields, preloads: preloads }) do
    result = Query.create_account_user(account_id, fields) |> Repo.transaction()
    do_create_user_response(result, preloads)
  end
  defp do_create_user(request = %{ vas: %{ account_id: account_id }, fields: fields, preloads: preloads }) do
    fields = Map.merge(fields, %{ "role" => "customer" })
    result = Query.create_account_user(account_id, fields) |> Repo.transaction()
    do_create_user_response(result, preloads)
  end
  defp do_create_user_response({:ok, %{ user: user}}, preloads) do
    user = Repo.preload(user, User.Query.preloads(preloads))
    {:ok, %AccessResponse{ data: user }}
  end
  defp do_create_user_response({:error, failed_operation, failed_value, _}, _) do
    {:error, %AccessResponse{ errors: failed_value.errors }}
  end

  def get_user(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- authorize(vas, "identity.get_user") do
      do_get_user(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_get_user(%AccessRequest{ vas: %{ user_id: user_id }, preloads: preloads, locale: locale }) do
    user =
      User
      |> Repo.get!(user_id)
      |> Repo.preload(User.Query.preloads(preloads))
      |> Translation.translate(locale)

    {:ok, %AccessResponse{ data: user }}
  end

  def delete_user(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- authorize(vas, "identity.delete_user") do
      cond do
        role == "customer" && vas[:user_id] == request.params.user_id -> do_delete_user(request)
        role == "customer" -> {:error, :access_denied}
        true -> do_delete_user(request)
      end
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_delete_user(request = %AccessRequest{ vas: vas, params: %{ user_id: user_id } }) do
    user = User |> User.Query.member_of_account(vas[:account_id]) |> Repo.get(user_id)

    Repo.delete!(user)

    {:ok, %AccessResponse{}}
  end

  #
  # RefreshToken
  #
  def get_refresh_token(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- authorize(vas, "identity.get_refresh_token") do
      do_get_refresh_token(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_get_refresh_token(request = %AccessRequest{ vas: %{ account_id: account_id }, locale: locale }) do
    refresh_token =
      RefreshToken.Query.storefront()
      |> Repo.get_by(account_id: account_id)

    {:ok, %AccessResponse{ data: refresh_token }}
  end
end
