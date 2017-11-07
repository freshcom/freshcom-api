defmodule BlueJet.Identity.TestHelper do
  alias BlueJet.Identity.User
  alias BlueJet.Identity.Account
  alias BlueJet.Identity.AccountMembership
  alias BlueJet.Repo

  def create_identity("guest") do
    account = Repo.insert!(%Account{})

    %{ vas: %{ account_id: account.id }, account: account }
  end
  def create_identity(role) do
    account = Repo.insert!(%Account{})
    user = Repo.insert!(%User{
      email: Faker.Internet.email(),
      first_name: Faker.Name.first_name(),
      last_name: Faker.Name.last_name(),
      encrypted_password: Comeonin.Bcrypt.hashpwsalt("test1234"),
      default_account_id: account.id
    })
    Repo.insert!(%AccountMembership{
      user_id: user.id,
      account_id: account.id,
      role: role
    })

    %{ vas: %{ account_id: account.id, user_id: user.id }, account: account, user: user }
  end
end