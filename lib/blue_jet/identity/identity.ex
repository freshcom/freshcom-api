defmodule BlueJet.Identity do
  use BlueJet, :context

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
      default_locale = fields["default_locale"]

      Multi.new()
      |> Multi.insert(:account, Account.changeset(%Account{ mode: "live", default_locale: default_locale }, fields, default_locale))
      |> Multi.run(:test_account, fn(%{ account: account }) ->
          changeset = Account.changeset(%Account{ live_account_id: account.id, mode: "test", default_locale: default_locale }, fields, default_locale)
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
      |> Multi.append(create_account(%{ "name" => fields["account_name"], "default_locale" => fields["default_locale"] }))
      |> Multi.run(:user, fn(%{ account: account }) ->
          Repo.insert(User.changeset(%User{}, Map.merge(fields, %{ "default_account_id" => account.id })))
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

      Multi.new()
      |> Multi.insert(:user, User.changeset(%User{}, Map.merge(fields, %{ "default_account_id" => account_id, "account_id" => account_id })))
      |> Multi.run(:account_membership, fn(%{ user: user }) ->
          Repo.insert(
            AccountMembership.changeset(%AccountMembership{}, %{
              account_id: account_id,
              user_id: user.id,
              role: Map.get(fields, "role")
            })
          )
        end)
      |> Multi.run(:urt_live, fn(%{ user: user }) ->
          if live_account_id do
            refresh_token = Repo.insert!(RefreshToken.changeset(%RefreshToken{}, %{ account_id: live_account_id, user_id: user.id }))
            {:ok, refresh_token}
          else
            {:ok, nil}
          end
        end)
      |> Multi.run(:urt_test, fn(%{ user: user }) ->
          if test_account_id do
            refresh_token = Repo.insert!(RefreshToken.changeset(%RefreshToken{}, %{ account_id: test_account_id, user_id: user.id }))
            {:ok, refresh_token}
          else
            {:ok, nil}
          end
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

  def authorize_request(request = %{ vas: vas }, endpoint) do
    with {:ok, %{ role: role, account: account }} <- authorize(vas, endpoint) do
      {:ok, %{ request | role: role, account: account }}
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def create_token(%{ fields: fields }) do
    with {:ok, token} <- Authentication.create_token(fields) do
      {:ok, %AccessResponse{ data: token }}
    else
      {:error, errors} -> {:error, %AccessResponse{ errors: errors }}
    end
  end

  ####
  # Account
  ####
  def list_account(request) do
    with {:ok, request} <- preprocess_request(request, "identity.list_account") do
      request
      |> do_list_account()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_account(request = %{ account: account, vas: %{ user_id: user_id } }) do
    accounts =
      Account
      |> Account.Query.has_member(user_id)
      |> Account.Query.live()
      |> Repo.all()
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ data: accounts, meta: %{ locale: request.locale } }}
  end

  def get_account(request) do
    with {:ok, request} <- preprocess_request(request, "identity.get_account") do
      request
      |> do_get_account()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_account(request = %{ account: account }) do
    account = Translation.translate(account, request.locale, account.default_locale)
    {:ok, %AccessResponse{ data: account, meta: %{ locale: request.locale } }}
  end

  def update_account(request) do
    with {:ok, request} <- preprocess_request(request, "identity.update_account") do
      request
      |> do_update_account()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  # TODO: also need to update the test account accordingly
  def do_update_account(request = %{ account: account, fields: fields }) do
    changeset = Account.changeset(account, fields, request.locale)

    with {:ok, account} <- Repo.update(changeset) do
      account = Translation.translate(account, request.locale, account.default_locale)
      {:ok, %AccessResponse{ data: account, meta: %{ locale: request.locale } }}
    else
      {:error, changeset} -> {:error, %AccessResponse{ errors: changeset.errors }}
    end
  end

  ####
  # User
  ####
  defp user_response(nil, _), do: {:error, :not_found}

  defp user_response(user, request = %{ account: account }) do
    preloads = User.Query.preloads(request.preloads, role: request.role)

    user =
      user
      |> User.put_role(account)
      |> Repo.preload(preloads)
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: user }}
  end

  def create_user(request) do
    with {:ok, request} <- preprocess_request(request, "identity.create_user") do
      request
      |> do_create_user()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_user(request = %{ role: "anonymous", fields: fields }) do
    Query.create_global_user(fields)
    |> Repo.transaction()
    |> do_create_user_response(request)
  end

  def do_create_user(request = %{ role: "guest", account: account, fields: fields }) do
    fields = Map.merge(fields, %{ "role" => "customer" })

    Query.create_account_user(account.id, fields)
    |> Repo.transaction()
    |> do_create_user_response(request)
  end

  def do_create_user(request = %{ account: account, fields: fields }) do
    Query.create_account_user(account.id, fields)
    |> Repo.transaction()
    |> do_create_user_response(request)
  end

  # Global user
  def do_create_user_response({:ok, %{ user: user, account: account }}, request) do
    user_response(user, %{ request | account: account })
  end

  # Account user
  def do_create_user_response({:ok, %{ user: user }}, request) do
    user_response(user, request)
  end

  def do_create_user_response({:error, _, failed_value, _}, _) do
    {:error, %AccessResponse{ errors: failed_value.errors }}
  end

  def get_user(request) do
    with {:ok, request} <- preprocess_request(request, "identity.get_user") do
      request
      |> do_get_user()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_user(request = %{ vas: %{ user_id: user_id } }) do
    User
    |> Repo.get(user_id)
    |> user_response(request)
  end

  def delete_user(request = %{ vas: vas, params: %{ "id" => id } }) do
    with {:ok, request} <- preprocess_request(request, "identity.delete_user") do
      cond do
        # Customer user cannot delete a user other than himself
        request.role == "customer" && vas[:user_id] != id ->
          {:error, :access_denied}

        # Allow other role to delete
        true ->
          request
          |> do_delete_user()
      end
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_user(%{ account: account, params: %{ "id" => id } }) do
    user =
      User.Query.default()
      |> User.Query.member_of_account(account.id)
      |> Repo.get(id)

    if user do
      Repo.delete!(user)
      {:ok, %AccessResponse{}}
    else
      {:error, :not_found}
    end
  end

  #
  # RefreshToken
  #
  def get_refresh_token(request) do
    with {:ok, request} <- preprocess_request(request, "identity.get_refresh_token") do
      request
      |> do_get_refresh_token()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_refresh_token(%{ account: account }) do
    refresh_token =
      RefreshToken.Query.publishable()
      |> Repo.get_by(account_id: account.id)

    if refresh_token do
      refresh_token = %{ refresh_token | prefixed_id: RefreshToken.prefix_id(refresh_token) }
      {:ok, %AccessResponse{ data: refresh_token }}
    else
      {:error, :not_found}
    end
  end
end
