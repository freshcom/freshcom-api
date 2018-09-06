defmodule BlueJet.NotificationTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.{Account, User}

  alias BlueJet.Notification
  alias BlueJet.Notification.{ServiceMock, Trigger, Email, EmailTemplate, Sms, SmsTemplate}

  #
  # MARK: Trigger
  #
  describe "list_trigger/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Notification.list_trigger(request)
    end

    test "when request is valid" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:list_trigger, fn(_, _) ->
          [%Trigger{}]
         end)
      |> expect(:count_trigger, fn(_, _) ->
          1
         end)
      |> expect(:count_trigger, fn(_, _) ->
          1
         end)

      {:ok, _} = Notification.list_trigger(request)
    end
  end

  describe "create_trigger/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Notification.create_trigger(request)
    end

    test "when request is valid" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:create_trigger, fn(fields, _) ->
          assert fields == request.fields

          {:ok, %Trigger{}}
         end)

      {:ok, _} = Notification.create_trigger(request)
    end
  end

  describe "get_trigger/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, error} = Notification.get_trigger(request)
      assert error == :access_denied
    end

    test "when request is valid" do
      trigger = %Trigger{ id: Ecto.UUID.generate() }

      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "administrator",
        params: %{ "id" => trigger.id }
      }

      ServiceMock
      |> expect(:get_trigger, fn(identifiers, _) ->
          assert identifiers.id == trigger.id

          {:ok, %Trigger{}}
         end)

      {:ok, _} = Notification.get_trigger(request)
    end
  end

  describe "update_trigger/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Notification.update_trigger(request)
    end

    test "request is valid" do
      trigger = %Trigger{ id: Ecto.UUID.generate() }

      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "administrator",
        params: %{ "id" => trigger.id },
        fields: %{ "name" => "hihi" }
      }

      ServiceMock
      |> expect(:update_trigger, fn(identifiers, fields, _) ->
          assert identifiers.id == trigger.id
          assert fields == request.fields

          {:ok, %Trigger{}}
         end)

      {:ok, _} = Notification.update_trigger(request)
    end
  end

  describe "delete_trigger/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Notification.delete_trigger(request)
    end

    test "when request is valid" do
      trigger = %Trigger{ id: Ecto.UUID.generate() }

      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "administrator",
        params: %{ "id" => trigger.id }
      }

      ServiceMock
      |> expect(:delete_trigger, fn(identifiers, _) ->
          assert identifiers.id == trigger.id

          {:ok, %Trigger{}}
         end)

      {:ok, _} = Notification.delete_trigger(request)
    end
  end

  #
  # MARK: Email
  #
  describe "list_email/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Notification.list_email(request)
    end

    test "when request is valid" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:list_email, fn(_, _) ->
          [%Email{}]
         end)
      |> expect(:count_email, fn(_, _) ->
          1
         end)
      |> expect(:count_email, fn(_, _) ->
          1
         end)

      {:ok, _} = Notification.list_email(request)
    end
  end

  describe "get_email/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, error} = Notification.get_email(request)
      assert error == :access_denied
    end

    test "when request is valid" do
      email = %Email{ id: Ecto.UUID.generate() }

      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "administrator",
        params: %{ "id" => email.id }
      }

      ServiceMock
      |> expect(:get_email, fn(identifiers, _) ->
          assert identifiers.id == email.id

          {:ok, %Email{}}
         end)

      {:ok, _} = Notification.get_email(request)
    end
  end

  #
  # MARK: Email Template
  #
  describe "list_email_template/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Notification.list_email_template(request)
    end

    test "when request is valid" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:list_email_template, fn(_, _) ->
          [%Email{}]
         end)
      |> expect(:count_email_template, fn(_, _) ->
          1
         end)
      |> expect(:count_email_template, fn(_, _) ->
          1
         end)

      {:ok, _} = Notification.list_email_template(request)
    end
  end

  describe "create_email_template/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Notification.create_email_template(request)
    end

    test "when request is valid" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:create_email_template, fn(fields, _) ->
          assert fields == request.fields

          {:ok, %EmailTemplate{}}
         end)

      {:ok, _} = Notification.create_email_template(request)
    end
  end

  describe "get_email_template/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Notification.get_email_template(request)
    end

    test "when request is valid" do
      email = %EmailTemplate{ id: Ecto.UUID.generate() }

      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "administrator",
        params: %{ "id" => email.id }
      }

      ServiceMock
      |> expect(:get_email_template, fn(identifiers, _) ->
          assert identifiers.id == email.id

          {:ok, %EmailTemplate{}}
         end)

      {:ok, _} = Notification.get_email_template(request)
    end
  end

  describe "update_email_template/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Notification.update_email_template(request)
    end

    test "request is valid" do
      email_template = %EmailTemplate{ id: Ecto.UUID.generate() }

      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "administrator",
        params: %{ "id" => email_template.id },
        fields: %{ "name" => "hihi" }
      }

      ServiceMock
      |> expect(:update_email_template, fn(identifiers, fields, _) ->
          assert identifiers.id == email_template.id
          assert fields == request.fields

          {:ok, %EmailTemplate{}}
         end)

      {:ok, _} = Notification.update_email_template(request)
    end
  end

  describe "delete_email_template/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Notification.delete_email_template(request)
    end

    test "when request is valid" do
      email_template = %EmailTemplate{ id: Ecto.UUID.generate() }

      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "administrator",
        params: %{ "id" => email_template.id }
      }

      ServiceMock
      |> expect(:delete_email_template, fn(identifiers, _) ->
          assert identifiers.id == email_template.id

          {:ok, %EmailTemplate{}}
         end)

      {:ok, _} = Notification.delete_email_template(request)
    end
  end

  #
  # MARK: SMS
  #
  describe "list_sms/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Notification.list_sms(request)
    end

    test "when request is valid" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:list_sms, fn(_, _) ->
          [%Sms{}]
         end)
      |> expect(:count_sms, fn(_, _) ->
          1
         end)
      |> expect(:count_sms, fn(_, _) ->
          1
         end)

      {:ok, _} = Notification.list_sms(request)
    end
  end

  describe "get_sms/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Notification.get_sms(request)
    end

    test "request is valid" do
      sms = %Sms{ id: Ecto.UUID.generate() }

      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "administrator",
        params: %{ "id" => sms.id }
      }

      ServiceMock
      |> expect(:get_sms, fn(identifiers, _) ->
          assert identifiers.id == sms.id

          {:ok, %Sms{}}
         end)

      {:ok, _} = Notification.get_sms(request)
    end
  end

  #
  # MARK: SMS Template
  #
  describe "list_sms_template/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Notification.list_sms_template(request)
    end

    test "when request is valid" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:list_sms_template, fn(_, _) ->
          [%Email{}]
         end)
      |> expect(:count_sms_template, fn(_, _) ->
          1
         end)
      |> expect(:count_sms_template, fn(_, _) ->
          1
         end)

      {:ok, _} = Notification.list_sms_template(request)
    end
  end

  describe "create_sms_template/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Notification.create_sms_template(request)
    end

    test "when request is valid" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:create_sms_template, fn(fields, _) ->
          assert fields == request.fields

          {:ok, %SmsTemplate{}}
         end)

      {:ok, _} = Notification.create_sms_template(request)
    end
  end

  describe "get_sms_template/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Notification.get_sms_template(request)
    end

    test "when request is valid" do
      sms_template = %SmsTemplate{ id: Ecto.UUID.generate() }
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "administrator",
        params: %{ "id" => sms_template.id }
      }

      ServiceMock
      |> expect(:get_sms_template, fn(identifiers, _) ->
          assert identifiers.id == sms_template.id

          {:ok, %SmsTemplate{}}
         end)

      {:ok, _} = Notification.get_sms_template(request)
    end
  end

  describe "update_sms_template/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Notification.update_sms_template(request)
    end

    test "request is valid" do
      sms_template = %EmailTemplate{ id: Ecto.UUID.generate() }

      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "administrator",
        params: %{ "id" => sms_template.id },
        fields: %{ "name" => "hihi" }
      }

      ServiceMock
      |> expect(:update_sms_template, fn(identifiers, fields, _) ->
          assert identifiers.id == sms_template.id
          assert fields == request.fields

          {:ok, %EmailTemplate{}}
         end)

      {:ok, _} = Notification.update_sms_template(request)
    end
  end

  describe "delete_sms_template/1" do
    test "when role is not authorized" do
      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "customer"
      }

      {:error, :access_denied} = Notification.delete_sms_template(request)
    end

    test "request is valid" do
      sms_template = %SmsTemplate{ id: Ecto.UUID.generate() }

      request = %ContextRequest{
        account: %Account{},
        user: %User{},
        role: "administrator",
        params: %{ "id" => sms_template.id }
      }

      ServiceMock
      |> expect(:delete_sms_template, fn(identifiers, _) ->
          assert identifiers.id == sms_template.id

          {:ok, %SmsTemplate{}}
         end)

      {:ok, _} = Notification.delete_sms_template(request)
    end
  end
end
