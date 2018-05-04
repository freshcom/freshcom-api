defmodule BlueJet.FileStorageTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.{Account, User}
  alias BlueJet.FileStorage
  alias BlueJet.FileStorage.ServiceMock
  alias BlueJet.FileStorage.{File, FileCollection, FileCollectionMembership}

  describe "list_file/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: nil,
        user: nil,
        role: "anonymous"
      }

      {:error, :access_denied} = FileStorage.list_file(request)
    end

    test "when role is guest and no file collection ID is provided" do
      request = %AccessRequest{
        account: %Account{},
        user: %User{},
        role: "guest"
      }

      {:error, :access_denied} = FileStorage.list_file(request)
    end

    test "when role is customer and file collection ID is provided" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "guest",
        filter: %{ collection_id: Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:list_file, fn(fields, opts) ->
          assert fields[:filter][:status] == "uploaded"
          assert fields[:filter][:collection_id] == request.filter[:collection_id]
          assert opts[:account] == account

          [%File{}]
         end)
      |> expect(:count_file, fn(fields, opts) ->
          assert fields[:filter][:status] == "uploaded"
          assert fields[:filter][:collection_id] == request.filter[:collection_id]
          assert opts[:account] == account

          1
         end)
      |> expect(:count_file, fn(fields, opts) ->
          assert fields[:filter][:status] == "uploaded"
          assert fields[:filter][:collection_id] == request.filter[:collection_id]
          assert opts[:account] == account

          1
         end)


      {:ok, _} = FileStorage.list_file(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "administrator"
      }

      ServiceMock
      |> expect(:list_file, fn(fields, opts) ->
          assert fields[:filter][:status] == "uploaded"
          assert opts[:account] == account

          [%File{}]
         end)
      |> expect(:count_file, fn(fields, opts) ->
          assert fields[:filter][:status] == "uploaded"
          assert opts[:account] == account

          1
         end)
      |> expect(:count_file, fn(fields, opts) ->
          assert fields[:filter][:status] == "uploaded"
          assert opts[:account] == account

          1
         end)

      {:ok, _} = FileStorage.list_file(request)
    end
  end

  describe "create_file/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: nil,
        user: nil,
        role: "anonymous"
      }

      {:error, :access_denied} = FileStorage.create_file(request)
    end

    test "when request is valid" do
      account = %Account{}
      user = %User{ id: Ecto.UUID.generate() }
      request = %AccessRequest{
        account: account,
        user: user,
        role: "administrator",
        fields: %{
          "name" => Faker.Commerce.product_name()
        }
      }

      ServiceMock
      |> expect(:create_file, fn(fields, opts) ->
          assert fields == Map.merge(request.fields, %{ "user_id" => user.id })
          assert opts[:account] == account

          {:ok, %File{}}
         end)

      {:ok, _} = FileStorage.create_file(request)
    end
  end

  describe "get_file/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: nil,
        user: nil,
        role: "anonymous"
      }

      {:error, :access_denied} = FileStorage.get_file(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: nil,
        role: "guest",
        params: %{ "id" => Ecto.UUID.generate() }
      }

      ServiceMock
      |> expect(:get_file, fn(identifiers, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert identifiers[:status] == "uploaded"
          assert opts[:account] == account

          %File{}
         end)

      {:ok, _} = FileStorage.get_file(request)
    end
  end

  describe "update_file/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: nil,
        user: nil,
        role: "anonymous"
      }

      {:error, :access_denied} = FileStorage.update_file(request)
    end

    test "when request is valid" do
      account = %Account{}
      request = %AccessRequest{
        account: account,
        user: %User{},
        role: "administrator",
        params: %{ "id" => Ecto.UUID.generate() },
        fields: %{
          "status" => "uploaded"
        }
      }

      ServiceMock
      |> expect(:update_file, fn(id, fields, opts) ->
          assert id == request.params["id"]
          assert fields == request.fields
          assert opts[:account] == account

          {:ok, %File{}}
         end)

      {:ok, _} = FileStorage.update_file(request)
    end
  end

  describe "delete_file/1" do
    test "when role is not authorized" do
      request = %AccessRequest{
        account: %Account{},
        user: nil,
        role: "guest"
      }

      {:error, :access_denied} = FileStorage.delete_file(request)
    end

    test "when role is customer and target file is not create by this customer" do
      account = %Account{}
      user = %User{ id: Ecto.UUID.generate() }
      file = %File{ user_id: Ecto.UUID.generate() }
      request = %AccessRequest{
        account: account,
        user: user,
        role: "customer",
        params: %{ "id" => file.id }
      }

      ServiceMock
      |> expect(:get_file, fn(identifiers, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert identifiers[:user_id] == user.id
          assert opts[:account] == account

          nil
         end)

      {:error, :access_denied} = FileStorage.delete_file(request)
    end

    test "when role is customer and target file is create by this customer" do
      account = %Account{}
      user = %User{ id: Ecto.UUID.generate() }
      file = %File{ user_id: user.id }
      request = %AccessRequest{
        account: account,
        user: user,
        role: "customer",
        params: %{ "id" => file.id }
      }

      ServiceMock
      |> expect(:get_file, fn(identifiers, opts) ->
          assert identifiers[:id] == request.params["id"]
          assert identifiers[:user_id] == user.id
          assert opts[:account] == account

          {:ok, file}
         end)

      ServiceMock
      |> expect(:delete_file, fn(id, opts) ->
          assert id == request.params["id"]
          assert opts[:account] == account

          {:ok, file}
         end)

      {:ok, _} = FileStorage.delete_file(request)
    end

    test "when request is valid" do
      account = %Account{}
      file = %File{ user_id: Ecto.UUID.generate() }
      request = %AccessRequest{
        account: account,
        user: %User{ id: Ecto.UUID.generate() },
        role: "administrator",
        params: %{ "id" => file.id }
      }

      ServiceMock
      |> expect(:delete_file, fn(id, opts) ->
          assert id == request.params["id"]
          assert opts[:account] == account

          {:ok, file}
         end)

      {:ok, _} = FileStorage.delete_file(request)
    end
  end
end
