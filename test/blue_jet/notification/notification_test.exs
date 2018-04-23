defmodule BlueJet.NotificationTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.{Account, User}

  alias BlueJet.Notification
  alias BlueJet.Notification.{ServiceMock, Trigger, Email, Sms}

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

  describe "get_email/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, error} = Notification.get_email(request)
      assert error == :access_denied
    end

    test "request is valid" do
      email = %Email{ id: Ecto.UUID.generate() }

      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "administrator",
        params: %{ "id" => email.id }
      }

      ServiceMock
      |> expect(:get_email, fn(identifiers, _) ->
          assert identifiers[:id] == email.id

          {:ok, %Email{}}
         end)

      {:ok, _} = Notification.get_email(request)
    end
  end

  describe "get_sms/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, error} = Notification.get_sms(request)
      assert error == :access_denied
    end

    test "request is valid" do
      sms = %Sms{ id: Ecto.UUID.generate() }

      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "administrator",
        params: %{ "id" => sms.id }
      }

      ServiceMock
      |> expect(:get_sms, fn(identifiers, _) ->
          assert identifiers[:id] == sms.id

          {:ok, %Sms{}}
         end)

      {:ok, _} = Notification.get_sms(request)
    end
  end
end
