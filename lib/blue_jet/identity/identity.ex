defmodule BlueJet.Identity do
  use BlueJet, :context

  alias Ecto.Changeset
  alias BlueJet.Identity.Authorization
  alias BlueJet.Identity.User
  alias BlueJet.Identity.RefreshToken
  alias BlueJet.Identity.AccountMembership
  alias BlueJet.Identity.Account

  defmodule Query do
    alias Ecto.Multi

    def create_account(fields) do
      Multi.new()
      |> Multi.insert(:account, Account.changeset(%Account{}, fields))
    end

    def create_global_user(fields) do
      Multi.new()
      |> Multi.append(create_account(%{ name: fields.account_name }))
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
      |> Multi.run(:refresh_tokens, fn(%{ account: account, user: user}) ->
          refresh_tokens = [
            Repo.insert!(RefreshToken.changeset(%RefreshToken{}, %{ account_id: account.id })),
            Repo.insert!(RefreshToken.changeset(%RefreshToken{}, %{ account_id: account.id, user_id: user.id })),
            Repo.insert!(RefreshToken.changeset(%RefreshToken{}, %{ user_id: user.id }))
          ]

          {:ok, refresh_tokens}
        end)
    end

    def create_account_user(account_id, fields) do
      Multi.new()
      |> Multi.insert(:user, User.changeset(%User{}, Map.merge(fields, %{ default_account_id: account_id, account_id: account_id })))
      |> Multi.run(:account_membership, fn(%{ user: user }) ->
          account_membership = Repo.insert!(
            AccountMembership.changeset(%AccountMembership{}, %{
              account_id: account_id,
              user_id: user.id,
              role: Map.get(fields, :role)
            })
          )

          {:ok, account_membership}
        end)
      |> Multi.run(:user_refresh_token, fn(%{ user: user }) ->
          Repo.insert(RefreshToken.changeset(%RefreshToken{}, %{ account_id: account_id, user_id: user.id }))
        end)
    end
  end


  def authorize(vas = %{}, endpoint) do
    Authorization.authorize(vas, endpoint)
  end

  def create_token() do

  end

  # def authenticate(args) do
  #   Authentication.get_token(args)
  # end

  ####
  # Account
  ####
  def get_account(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Authorization.authorize(vas, "identity.get_account") do
      do_get_account(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_get_account(%AccessRequest{ vas: %{ account_id: account_id }, locale: locale }) do
    account =
      Account
      |> Repo.get!(account_id)
      |> Translation.translate(locale)

    {:ok, %AccessResponse{ data: account }}
  end

  # def update_account(%AccessRequest{ vas: %{ account_id: account_id } }) do
  #   defaults = %{ preloads: [], fields: %{} }
  #   request = Map.merge(defaults, request)
  #   account = Repo.get_by!(Account, id: vas[:account_id])
  #   changeset = Account.changeset(account, request.fields)
  #   update_account(changeset)
  # end
  # def update_account(changeset = %Changeset{ valid?: true }) do
  #   Repo.transaction(fn ->
  #     account = Repo.update!(changeset)
  #     with {:ok, account} <- Account.process(account, changeset) do
  #       account
  #     else
  #       {:error, errors} -> Repo.rollback(errors)
  #     end
  #   end)
  # end
  # def update_account(changeset) do
  #   {:error, changeset.errors}
  # end

  ####
  # User
  ####
  def create_user(request = %AccessRequest{ vas: vas, fields: fields, preloads: preloads }) do
    with {:ok, role} <- Authorization.authorize(vas, "identity.create_user") do
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
    fields = Map.merge(fields, %{ role: "customer" })
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
    with {:ok, role} <- Authorization.authorize(vas, "identity.get_user") do
      do_get_user(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_get_user(%AccessRequest{ vas: %{ account_id: account_id, user_id: user_id }, preloads: preloads, locale: locale }) do
    user = Repo.get(User, user_id)
    do_get_user_response(user, preloads, locale)
  end
  defp do_get_user_response(nil) do
    {:error, :not_found}
  end
  defp do_get_user_response(user, preloads, locale) do
    user =
      user
      |> Repo.preload(User.Query.preloads(preloads))
      |> Translation.translate(locale)

    {:ok, %AccessResponse{ data: user }}
  end
end
