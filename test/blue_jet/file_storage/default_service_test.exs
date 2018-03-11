defmodule BlueJet.FileStorage.ServiceTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.Account
  alias BlueJet.FileStorage.{File, FileCollection, FileCollectionMembership}
  alias BlueJet.FileStorage.DefaultService
  alias BlueJet.FileStorage.S3ClientMock

  describe "list_file/2" do
    test "file for different account is not returned" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })
      Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })
      Repo.insert!(%File{
        account_id: other_account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })

      S3ClientMock
      |> expect(:get_presigned_url, 2, fn(_, _) -> nil end)

      files = DefaultService.list_file(%{ account: account })
      assert length(files) == 2
    end

    test "pagination should change result size" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })
      Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })
      Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })
      Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })
      Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })

      S3ClientMock
      |> expect(:get_presigned_url, 5, fn(_, _) -> nil end)

      files = DefaultService.list_file(%{ account: account, pagination: %{ size: 3, number: 1 } })
      assert length(files) == 3

      files = DefaultService.list_file(%{ account: account, pagination: %{ size: 3, number: 2 } })
      assert length(files) == 2
    end
  end

  describe "count_file/2" do
    test "file for different account is not returned" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })
      Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })
      Repo.insert!(%File{
        account_id: other_account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })

      assert DefaultService.count_file(%{ account: account }) == 2
    end

    test "only file matching filter is counted" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%Account{})
      Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890,
        label: "test"
      })
      Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })
      Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })

      assert DefaultService.count_file(%{ filter: %{ label: "test" } }, %{ account: account }) == 1
    end
  end

  describe "create_file/2" do
    test "when given valid fields" do
      account = Repo.insert!(%Account{})

      S3ClientMock
      |> expect(:get_presigned_url, fn(_, _) -> nil end)

      fields = %{
        "name" => Faker.String.base64(5),
        "content_type" => "image/png",
        "size_bytes" => 19203
      }

      {:ok, file} = DefaultService.create_file(fields, %{ account: account })

      assert file
    end
  end

  describe "get_file/2" do
    test "when given id" do
      account = Repo.insert!(%Account{})
      file = Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })

      S3ClientMock
      |> expect(:get_presigned_url, fn(_, _) -> nil end)

      assert DefaultService.get_file(%{ id: file.id }, %{ account: account })
    end

    test "when given id belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      file = Repo.insert!(%File{
        account_id: other_account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })

      refute DefaultService.get_file(%{ id: file.id }, %{ account: account })
    end

    test "when give id does not exist" do
      account = Repo.insert!(%Account{})

      refute DefaultService.get_file(%{ id: Ecto.UUID.generate() }, %{ account: account })
    end
  end

  describe "update_file/2" do
    test "when given nil for file" do
      {:error, error} = DefaultService.update_file(nil, %{}, %{})
      assert error == :not_found
    end

    test "when given id does not exist" do
      account = Repo.insert!(%Account{})

      {:error, error} = DefaultService.update_file(Ecto.UUID.generate(), %{}, %{ account: account })
      assert error == :not_found
    end

    test "when given id belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      file = Repo.insert!(%File{
        account_id: other_account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })

      {:error, error} =DefaultService.update_file(file.id, %{}, %{ account: account })
      assert error == :not_found
    end

    test "when given valid id and invalid fields" do
      account = Repo.insert!(%Account{})
      file = Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })

      {:error, changeset} = DefaultService.update_file(file.id, %{ "status" => nil }, %{ account: account })
      assert length(changeset.errors) > 0
    end

    test "when given valid id and valid fields" do
      account = Repo.insert!(%Account{})
      file = Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })

      S3ClientMock
      |> expect(:get_presigned_url, fn(_, _) -> nil end)

      fields = %{
        "status" => "uploaded"
      }

      {:ok, file} = DefaultService.update_file(file.id, fields, %{ account: account })
      assert file
    end

    test "when given file and invalid fields" do
      account = Repo.insert!(%Account{})
      file = Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })

      {:error, changeset} = DefaultService.update_file(file, %{ "status" => nil }, %{ account: account })
      assert length(changeset.errors) > 0
    end

    test "when given file and valid fields" do
      account = Repo.insert!(%Account{})
      file = Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })

      S3ClientMock
      |> expect(:get_presigned_url, fn(_, _) -> nil end)

      fields = %{
        "status" => "uploaded"
      }

      {:ok, file} = DefaultService.update_file(file, fields, %{ account: account })
      assert file
    end
  end

  describe "delete_file/2" do
    test "when given valid file" do
      account = Repo.insert!(%Account{})
      file = Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })

      S3ClientMock
      |> expect(:delete_object, fn(_) -> nil end)

      {:ok, file} = DefaultService.delete_file(file, %{ account: account })

      assert file
      refute Repo.get(File, file.id)
    end

    test "when given valid id" do
      account = Repo.insert!(%Account{})
      file = Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })

      S3ClientMock
      |> expect(:delete_object, fn(_) -> nil end)

      {:ok, file} = DefaultService.delete_file(file.id, %{ account: account })

      assert file
      refute Repo.get(File, file.id)
    end
  end

  describe "list_file_collection/2" do
    test "file collection for different account is not returned" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      Repo.insert!(%FileCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      Repo.insert!(%FileCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      Repo.insert!(%FileCollection{
        account_id: other_account.id,
        name: Faker.String.base64(5)
      })

      file_collections = DefaultService.list_file_collection(%{ account: account })
      assert length(file_collections) == 2
    end

    test "pagination should change result size" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%FileCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      Repo.insert!(%FileCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      Repo.insert!(%FileCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      Repo.insert!(%FileCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      Repo.insert!(%FileCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })

      file_collections = DefaultService.list_file_collection(%{ account: account, pagination: %{ size: 3, number: 1 } })
      assert length(file_collections) == 3

      file_collections = DefaultService.list_file_collection(%{ account: account, pagination: %{ size: 3, number: 2 } })
      assert length(file_collections) == 2
    end
  end

  describe "count_file_collection/2" do
    test "file collection for different account is not returned" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      Repo.insert!(%FileCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      Repo.insert!(%FileCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      Repo.insert!(%FileCollection{
        account_id: other_account.id,
        name: Faker.String.base64(5)
      })

      assert DefaultService.count_file_collection(%{ account: account }) == 2
    end

    test "only file collection matching filter is counted" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%Account{})
      Repo.insert!(%FileCollection{
        account_id: account.id,
        name: Faker.String.base64(5),
        label: "test"
      })
      Repo.insert!(%FileCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      Repo.insert!(%FileCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })

      assert DefaultService.count_file_collection(%{ filter: %{ label: "test" } }, %{ account: account }) == 1
    end
  end

  describe "create_file_collection/2" do
    test "when given valid fields" do
      account = Repo.insert!(%Account{})
      file1 = Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })
      file2 = Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })

      fields = %{
        "name" => Faker.String.base64(5),
        "file_ids" => [file1.id, file2.id]
      }

      {:ok, file_collection} = DefaultService.create_file_collection(fields, %{ account: account })

      assert file_collection
      assert Repo.get_by(FileCollectionMembership, file_id: file1.id, collection_id: file_collection.id)
      assert Repo.get_by(FileCollectionMembership, file_id: file2.id, collection_id: file_collection.id)
    end
  end

  describe "get_file_collection/2" do
    test "when given id" do
      account = Repo.insert!(%Account{})
      file_collection = Repo.insert!(%FileCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })

      assert DefaultService.get_file_collection(%{ id: file_collection.id }, %{ account: account })
    end

    test "when given id belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      file_collection = Repo.insert!(%FileCollection{
        account_id: other_account.id,
        name: Faker.String.base64(5)
      })

      refute DefaultService.get_file_collection(%{ id: file_collection.id }, %{ account: account })
    end

    test "when give id does not exist" do
      account = Repo.insert!(%Account{})

      refute DefaultService.get_file_collection(%{ id: Ecto.UUID.generate() }, %{ account: account })
    end
  end

  describe "update_file_collection/2" do
    test "when given nil for file collection" do
      {:error, error} = DefaultService.update_file_collection(nil, %{}, %{})
      assert error == :not_found
    end

    test "when given id does not exist" do
      account = Repo.insert!(%Account{})

      {:error, error} = DefaultService.update_file_collection(Ecto.UUID.generate(), %{}, %{ account: account })
      assert error == :not_found
    end

    test "when given id belongs to a different account" do
      account = Repo.insert!(%Account{})
      other_account = Repo.insert!(%Account{})
      file = Repo.insert!(%FileCollection{
        account_id: other_account.id,
        name: Faker.String.base64(5)
      })

      {:error, error} = DefaultService.update_file_collection(file.id, %{}, %{ account: account })
      assert error == :not_found
    end

    test "when given valid id and invalid fields" do
      account = Repo.insert!(%Account{})
      file = Repo.insert!(%FileCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })

      {:error, changeset} = DefaultService.update_file_collection(file.id, %{ "status" => nil }, %{ account: account })
      assert length(changeset.errors) > 0
    end

    test "when given valid id and valid fields" do
      account = Repo.insert!(%Account{})
      file = Repo.insert!(%FileCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })

      fields = %{
        "status" => "draft"
      }

      {:ok, file} = DefaultService.update_file_collection(file.id, fields, %{ account: account })
      assert file
    end

    test "when given file collection and invalid fields" do
      account = Repo.insert!(%Account{})
      file = Repo.insert!(%FileCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })

      {:error, changeset} = DefaultService.update_file_collection(file, %{ "status" => nil }, %{ account: account })
      assert length(changeset.errors) > 0
    end

    test "when given file collection and valid fields" do
      account = Repo.insert!(%Account{})
      file = Repo.insert!(%FileCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })

      fields = %{
        "status" => "draft"
      }

      {:ok, file} = DefaultService.update_file_collection(file, fields, %{ account: account })
      assert file
    end
  end

  describe "delete_file_collection/2" do
    test "when given valid file collection" do
      account = Repo.insert!(%Account{})
      file_collection = Repo.insert!(%FileCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })

      {:ok, file_collection} = DefaultService.delete_file_collection(file_collection, %{ account: account })
      assert file_collection
      refute Repo.get(FileCollection, file_collection.id)
    end

    test "when given valid id" do
      account = Repo.insert!(%Account{})
      file_collection = Repo.insert!(%FileCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })

      {:ok, file_collection} = DefaultService.delete_file_collection(file_collection.id, %{ account: account })
      assert file_collection
      refute Repo.get(FileCollection, file_collection.id)
    end
  end

  describe "delete_file_collection_membership/2" do
    test "when given valid file collection" do
      account = Repo.insert!(%Account{})
      file_collection = Repo.insert!(%FileCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      file = Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })
      fcm = Repo.insert!(%FileCollectionMembership{
        account_id: account.id,
        collection_id: file_collection.id,
        file_id: file.id
      })


      {:ok, fcm} = DefaultService.delete_file_collection_membership(fcm, %{ account: account })

      assert fcm
      refute Repo.get(FileCollectionMembership, fcm.id)
    end

    test "when given valid id" do
      account = Repo.insert!(%Account{})
      file_collection = Repo.insert!(%FileCollection{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      file = Repo.insert!(%File{
        account_id: account.id,
        name: Faker.String.base64(5),
        content_type: "image/png",
        size_bytes: 19890
      })
      fcm = Repo.insert!(%FileCollectionMembership{
        account_id: account.id,
        collection_id: file_collection.id,
        file_id: file.id
      })

      {:ok, fcm} = DefaultService.delete_file_collection_membership(fcm.id, %{ account: account })

      assert fcm
      refute Repo.get(FileCollection, fcm.id)
    end
  end
end
