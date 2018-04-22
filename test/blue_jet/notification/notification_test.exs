defmodule BlueJet.NotificationTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.{Account, User}

  alias BlueJet.Notification
  alias BlueJet.Notification.{ServiceMock, Trigger}

  describe "update_trigger/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, error} = Notification.update_trigger(request)
      assert error == :access_denied
    end

    test "request is valid" do
      trigger = %Trigger{ id: Ecto.UUID.generate() }

      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "administrator",
        params: %{ "id" => trigger.id },
        fields: %{ "name" => "hihi" }
      }

      ServiceMock
      |> expect(:update_trigger, fn(id, fields, _) ->
          assert id == trigger.id
          assert fields == request.fields

          {:ok, %Trigger{}}
         end)

      {:ok, _} = Notification.update_trigger(request)
    end
  end
end
