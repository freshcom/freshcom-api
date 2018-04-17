defmodule BlueJet.Crm.EventHandlerTest do
  use BlueJet.EventHandlerCase

  alias BlueJet.Identity.{Account, User}
  alias BlueJet.Crm.Customer
  alias BlueJet.Crm.EventHandler
  alias BlueJet.Crm.ServiceMock

  describe "identity.user.update.success" do
    # Issue: GL#24
    test "when provided fields are invalid" do
      account = Repo.insert!(%Account{})
      user = Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        username: Faker.Internet.user_name(),
        password: "test1234"
      })
      Repo.insert!(%Customer{
        account_id: account.id,
        user_id: user.id
      })

      ServiceMock
      |> expect(:update_customer, fn(_, _, _) ->
          {:error, %{ errors: [email: {"can't be blank", [validation: :required]}] }}
         end)

      {:error, changeset} = EventHandler.handle_event("identity.user.update.success", %{
        user: user,
        account: account,
        changeset: %{ changes: %{ email: nil } }
      })

      assert changeset.errors
    end
  end
end
