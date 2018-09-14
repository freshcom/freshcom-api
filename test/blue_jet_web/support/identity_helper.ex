defmodule BlueJet.Identity.TestHelper do
  alias BlueJet.CreateRequest
  alias BlueJet.Repo
  alias BlueJet.Identity
  alias BlueJet.Identity.{Account, RefreshToken, AccountMembership}

  def create_standard_user(opts \\ []) do
    n = opts[:n] || 1

    {:ok, %{data: standard_user}} = Identity.create_user(%CreateRequest{
      fields: %{
        "name" => Faker.Name.name(),
        "username" => "standard_user#{n}@example.com",
        "email" => "standard_user#{n}@example.com",
        "password" => "standard1234",
        "default_locale" => "en"
      }
    })

    standard_user
  end

  def create_managed_user(standard_user, opts \\ []) do
    n = opts[:n] || 1
    role = opts[:role] || "developer"

    {:ok, %{data: managed_user}} = Identity.create_user(%CreateRequest{
      fields: %{
        "name" => Faker.Name.name(),
        "username" => "managed_user#{n}@example.com",
        "email" => "managed_user#{n}@example.com",
        "password" => "managed1234",
        "role" => role
      },
      vas: %{ account_id: standard_user.default_account_id, user_id: standard_user.id }
    })

    managed_user
  end

  def get_urt(user, opts \\ []) do
    mode = opts[:mode] || :live

    if mode == :live do
      %{ id: urt } = Repo.get_by(RefreshToken, user_id: user.id, account_id: user.default_account_id)

      urt
    else
      %{ id: test_account_id } = Repo.get_by(Account, mode: "test", live_account_id: user.default_account_id)
      %{ id: urt } = Repo.get_by(RefreshToken, user_id: user.id, account_id: test_account_id)

      urt
    end
  end

  def get_uat(user, opts \\ []) do
    urt = get_urt(user, opts)

    {:ok, %{data: %{access_token: uat}}} = Identity.create_access_token(%{
      fields: %{ "grant_type" => "refresh_token", "refresh_token" => urt }
    })

    uat
  end

  def get_pat(user) do
    %{ id: prt } = Repo.get_by(RefreshToken.Query.publishable(), account_id: user.default_account_id)
    {:ok, %{data: %{access_token: pat}}} = Identity.create_access_token(%{
      fields: %{ "grant_type" => "refresh_token", "refresh_token" => prt }
    })

    pat
  end

  def join_account(account_id, user_id) do
    Repo.insert!(%AccountMembership{
      account_id: account_id,
      user_id: user_id,
      role: "developer"
    })
  end
end