defmodule BlueJet.Identity.TestHelper do
  alias BlueJet.AccessRequest

  alias BlueJet.Identity
  alias BlueJet.Identity.User
  alias BlueJet.Identity.Account
  alias BlueJet.Identity.RefreshToken
  alias BlueJet.Identity.AccountMembership
  alias BlueJet.Repo

  def create_identity("guest") do
    account = Repo.insert!(%Account{})

    %{ vas: %{ account_id: account.id }, account: account }
  end

  def create_identity(role) do
    account = Repo.insert!(%Account{})
    email = Faker.Internet.email()
    user = Repo.insert!(%User{
      email: email,
      username: email,
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
    Repo.insert!(%RefreshToken{
      user_id: user.id,
      account_id: account.id
    })

    %{ vas: %{ account_id: account.id, user_id: user.id }, account: account, user: user }
  end

  def create_access_token(username, password) do
    {:ok, %{ data: %{ access_token: uat } }} = Identity.create_token(%AccessRequest{
      fields: %{ grant_type: "password", username: username, password: password }
    })

    uat
  end
end