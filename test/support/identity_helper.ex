defmodule BlueJet.Identity.TestHelper do
  alias BlueJet.Identity.Service

  alias BlueJet.Identity.RefreshToken
  alias BlueJet.Repo

  def account_fixture() do
    {:ok, account} = Service.create_account(%{
      name: Faker.Company.name()
    }, %{skip_dispatch: true})

    account
  end

  def account_fixture(user) do
    fields = %{name: Faker.Company.name()}
    opts = %{user: user, skip_dispatch: true}

    {:ok, account} = Service.create_account(fields, opts)

    account
  end

  def managed_user_fixture(account, fields \\ %{}) when not is_nil(account) do
    n = System.unique_integer([:positive])
    default_fields = %{
      name: Faker.Name.name(),
      username: "#{Faker.Internet.user_name()}#{n}",
      password: "test1234",
      email: "#{Faker.Internet.user_name()}#{n}@example.com",
      role: "administrator"
    }
    fields = Map.merge(default_fields, fields)
    opts = %{account: account, bypass_pvc_validation: true, skip_dispatch: true}

    {:ok, user} = Service.create_user(fields, opts)

    user
  end

  def standard_user_fixture(fields \\ %{}) do
    n = System.unique_integer([:positive])
    default_fields = %{
      name: Faker.Name.name(),
      username: "#{Faker.Internet.user_name()}#{n}",
      password: "test1234",
      email: "#{Faker.Internet.user_name()}#{n}@example.com"
    }
    fields = Map.merge(default_fields, fields)
    opts = %{account: nil, bypass_pvc_validation: true, skip_dispatch: true}

    {:ok, user} = Service.create_user(fields, opts)

    user
  end

  def account_membership_fixture() do
    standard_user = standard_user_fixture()
    membership = Service.get_account_membership(%{user_id: standard_user.id}, %{account: standard_user.default_account})

    %{membership | user: standard_user, account: standard_user.default_account}
  end

  def account_membership_fixture(for: :managed) do
    standard_user = standard_user_fixture()
    managed_user = managed_user_fixture(standard_user.default_account)
    membership = Service.get_account_membership(%{user_id: managed_user.id}, %{account: managed_user.account})

    %{membership | user: managed_user, account: managed_user.account}
  end

  def password_reset_token_fixture(user) do
    {:ok, user} = Service.create_password_reset_token(%{"username" => user.username}, %{account: user.account})
    user.password_reset_token
  end

  def get_prt(account) do
    BlueJet.Identity.Service.get_refresh_token(%{account: account}).prefixed_id
  end

  def get_urt(account, user) do
    Repo.get_by!(RefreshToken, account_id: account.id, user_id: user.id)
    |> RefreshToken.get_prefixed_id()
  end

  def get_pat(account) do
    prt = get_prt(account)
    {:ok, %{access_token: pat}} = BlueJet.Identity.Service.create_access_token(%{
      "grant_type" => "refresh_token",
      "refresh_token" => prt
    })

    pat
  end

  def get_uat(account, user) do
    urt = get_urt(account, user)
    {:ok, %{access_token: uat}} = BlueJet.Identity.Service.create_access_token(%{
      "grant_type" => "refresh_token",
      "refresh_token" => urt
    })

    uat
  end
end
