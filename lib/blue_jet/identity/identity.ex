defmodule BlueJet.Identity do
  use BlueJet, :context

  alias Ecto.Changeset
  alias BlueJet.Identity.Authentication
  alias BlueJet.Identity.Customer
  alias BlueJet.Identity.User
  alias BlueJet.Identity.RefreshToken
  alias BlueJet.Identity.AccountMembership
  alias BlueJet.Identity.Account
  alias BlueJet.Identity.Role
  alias BlueJet.Identity.RoleInstance
  alias BlueJet.Identity.Permission

  defmodule Query do
    alias Ecto.Multi

    def create_account(fields) do
      Multi.new()
      |> Multi.insert(:account, Account.changeset(%Account{}, fields))
      |> Multi.run(:system_roles, fn(%{ account: account }) ->
        system_roles = [
          Repo.insert!(Role.changeset(%Role{}, %{
            account_id: account.id,
            name: "Administrator",
            system_label: "administrator",
            permissions: Permission.default(:administrator)
          })),
          Repo.insert!(Role.changeset(%Role{}, %{
            account_id: account.id,
            name: "Developer",
            system_label: "developer",
            permissions: Permission.default(:developer)
          })),
          Repo.insert!(Role.changeset(%Role{}, %{
            account_id: account.id,
            name: "Support Personnel",
            system_label: "support_personnel",
            permissions: Permission.default(:support_personnel)
          })),
          Repo.insert!(Role.changeset(%Role{}, %{
            account_id: account.id,
            name: "Customer",
            system_label: "customer",
            permissions: Permission.default(:customer)
          }))
        ]

        {:ok, system_roles}
      end)
    end

    def create_global_user(fields) do
      Multi.new()
      |> Multi.append(create_account(%{ name: fields.account_name }))
      |> Multi.run(:user, fn(x = %{ account: account }) ->
          Repo.insert(User.changeset(%User{}, Map.merge(fields, %{ default_account_id: account.id })))
        end)
      |> Multi.run(:account_membership, fn(%{ account: account, user: user }) ->
          account_membership = Repo.insert!(
            AccountMembership.changeset(%AccountMembership{}, %{
              account_id: account.id,
              user_id: user.id
            })
          )

          {:ok, account_membership}
        end)
      |> Multi.run(:role_instance, fn(%{ account_membership: account_membership, account: account, system_roles: system_roles }) ->
          admin_role = Enum.find(system_roles, fn(role) ->
            role.system_label == "administrator"
          end)

          role_instance = Repo.insert!(RoleInstance.changeset(%RoleInstance{}, %{
            account_id: account.id,
            role_id: admin_role.id,
            account_membership_id: account_membership.id
          }))

          {:ok, role_instance}
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
      |> Multi.run(:user_refresh_token, fn(%{ user: user }) ->
          Repo.insert(RefreshToken.changeset(%RefreshToken{}, %{ account_id: account_id, user_id: user.id }))
        end)
    end
  end

  def authenticate(args) do
    Authentication.get_token(args)
  end

  ####
  # Account
  ####
  def get_account(%ContextRequest{ vas: %{ account_id: account_id }, locale: locale }) do
    account =
      Account
      |> Repo.get!(account_id)
      |> Translation.translate(locale)

    {:ok, %ContextResponse{ data: account }}
  end

  def update_account(request = %{ vas: vas, account_id: account_id }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)
    account = Repo.get_by!(Account, id: vas[:account_id])
    changeset = Account.changeset(account, request.fields)
    update_account(changeset)
  end
  def update_account(changeset = %Changeset{ valid?: true }) do
    Repo.transaction(fn ->
      account = Repo.update!(changeset)
      with {:ok, account} <- Account.process(account, changeset) do
        account
      else
        {:error, errors} -> Repo.rollback(errors)
      end
    end)
  end
  def update_account(changeset) do
    {:error, changeset.errors}
  end

  ####
  # User
  ####
  def create_user(request = %ContextRequest{ vas: vas, fields: fields, preloads: preloads }) when map_size(vas) == 0 do
    result = Query.create_global_user(fields) |> Repo.transaction()

    case result do
      {:ok, %{ user: user }} ->
        user = Repo.preload(user, User.Query.preloads(preloads))
        response = %ContextResponse{ data: user }

        {:ok, %ContextResponse{ data: user }}
      {:error, failed_operation, failed_value, _} ->
        {:error, %ContextResponse{ errors: failed_value.errors }}
      other -> IO.inspect other
    end
  end
  def create_user(request = %{ vas: %{ account_id: account_id }, fields: fields, preloads: preloads }) do
    result = Query.create_account_user(account_id, fields) |> Repo.transaction()

    case result do
      {:ok, %{ user: user }} ->
        user = Repo.preload(user, User.Query.preloads(preloads))
        response = %ContextResponse{ data: user }

        {:ok, %ContextResponse{ data: user }}
      {:error, failed_operation, failed_value, _} ->
        {:error, %ContextResponse{ errors: failed_value.errors }}
    end
  end

  def get_user!(request = %{ vas: _, user_id: user_id }) do
    defaults = %{ locale: "en", preloads: [] }
    request = Map.merge(defaults, request)

    user =
      User
      |> Repo.get!(user_id)
      |> Repo.preload(request.preloads)
      |> Translation.translate(request.locale)

    user
  end
end
