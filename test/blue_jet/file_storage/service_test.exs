defmodule BlueJet.FileStorage.ServiceTest do
  use BlueJet.ContextCase

  import BlueJet.FileStorage.TestHelper

  alias BlueJet.Identity.Account
  alias BlueJet.FileStorage.{File, FileCollection, FileCollectionMembership}
  alias BlueJet.FileStorage.Service

  describe "list_file/2 and count_file/2" do
    test "with valid request" do
      account1 = account_fixture()
      account2 = account_fixture()
      file_fixture(account1, %{status: "uploaded"})
      file_fixture(account1, %{status: "uploaded"})
      file_fixture(account1, %{status: "uploaded"})
      file_fixture(account1)
      file_fixture(account2)

      opts = %{account: account1, pagination: %{number: 1, size: 2}}
      query = %{filter: %{status: "uploaded"}}

      files = Service.list_file(query, opts)

      assert length(files) == 2
      assert Service.count_file(query, opts) == 3
    end
  end

  describe "create_file/2" do
    test "when given invalid fields" do
      account = account_fixture()

      {:error, %{errors: errors}} = Service.create_file(%{}, %{account: account})

      assert match_keys(errors, [:name, :content_type, :size_bytes])
    end

    test "when given valid fields" do
      account = account_fixture()

      fields = %{
        "name" => Faker.File.file_name(),
        "content_type" => Faker.File.mime_type(),
        "size_bytes" => System.unique_integer([:positive])
      }
      opts = %{account: account}

      {:ok, file} = Service.create_file(fields, opts)

      assert file.name == fields["name"]
      assert file.content_type == fields["content_type"]
      assert file.size_bytes == fields["size_bytes"]
    end
  end

  describe "get_file/2" do
    test "when given invalid id" do
      account = %Account{id: UUID.generate()}

      refute Service.get_file(%{id: UUID.generate()}, %{account: account})
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()
      file = file_fixture(account2)

      refute Service.get_file(%{id: file.id}, %{account: account1})
    end

    test "when given valid id" do
      account = account_fixture()
      target_file = file_fixture(account)

      file = Service.get_file(%{id: target_file.id}, %{account: account})

      assert file.id == target_file.id
    end
  end

  describe "update_file/2" do
    test "when given id not exist" do
      account = %Account{id: UUID.generate()}

      {:error, error} = Service.update_file(%{id: UUID.generate()}, %{}, %{account: account})

      assert error == :not_found
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()
      file = file_fixture(account2)

      {:error, error} = Service.update_file(%{id: file.id}, %{}, %{account: account1})

      assert error == :not_found
    end

    test "when given valid id and invalid fields" do
      account = account_fixture()
      file = file_fixture(account)

      {:error, %{errors: errors}} = Service.update_file(%{id: file.id}, %{"status" => nil}, %{account: account})

      assert match_keys(errors, [:status])
    end

    test "when given valid id and valid fields" do
      account = account_fixture()
      file = file_fixture(account)

      identifiers = %{id: file.id}
      fields = %{"status" => "uploaded"}
      opts = %{account: account}

      {:ok, file} = Service.update_file(identifiers, fields, opts)

      assert file.status == fields["status"]
    end
  end

  describe "delete_file/2" do
    test "when given id not exist" do
      account = %Account{id: UUID.generate()}

      {:error, error} = Service.delete_file(%{id: UUID.generate()}, %{account: account})

      assert error == :not_found
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()
      file = file_fixture(account2)

      {:error, error} = Service.delete_file(%{id: file.id}, %{account: account1})

      assert error == :not_found
    end

    test "when given valid id" do
      account = account_fixture()
      file = file_fixture(account)

      {:ok, file} = Service.delete_file(%{id: file.id}, %{account: account})

      refute Repo.get(File, file.id)
    end
  end

  describe "list_file_collection/2 and count_file_collection/2" do
    test "with valid request" do
      account1 = account_fixture()
      account2 = account_fixture()
      file_collection_fixture(account1, %{status: "draft"})
      file_collection_fixture(account1, %{status: "draft"})
      file_collection_fixture(account1, %{status: "draft"})
      file_collection_fixture(account1)
      file_collection_fixture(account2)

      opts = %{account: account1, pagination: %{number: 1, size: 2}}
      query = %{filter: %{status: "draft"}}

      collections = Service.list_file_collection(query, opts)

      assert length(collections) == 2
      assert Service.count_file_collection(query, opts) == 3
    end
  end

  describe "create_file_collection/2" do
    test "when given invalid fields" do
      account = %Account{id: UUID.generate()}

      {:error, %{errors: errors}} = Service.create_file_collection(%{}, %{account: account})

      assert match_keys(errors, [:name])
    end

    test "when given valid fields" do
      account = account_fixture()
      file1 = file_fixture(account)
      file2 = file_fixture(account)

      fields = %{
        "name" => Faker.Commerce.product_name(),
        "file_ids" => [file1.id, file2.id]
      }
      opts = %{account: account}

      {:ok, collection} = Service.create_file_collection(fields, opts)

      assert collection.name == fields["name"]
      assert Repo.get_by(FileCollectionMembership, file_id: file1.id, collection_id: collection.id)
      assert Repo.get_by(FileCollectionMembership, file_id: file2.id, collection_id: collection.id)
    end
  end

  describe "get_file_collection/2" do
    test "when give id does not exist" do
      account = %Account{id: UUID.generate()}

      refute Service.get_file_collection(%{id: UUID.generate()}, %{account: account})
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()
      collection = file_collection_fixture(account2)

      refute Service.get_file_collection(%{id: collection.id}, %{account: account1})
    end

    test "when given valid id" do
      account = account_fixture()
      target_collection = file_collection_fixture(account)

      identifiers = %{id: target_collection.id}
      opts = %{account: account}

      collection = Service.get_file_collection(identifiers, opts)

      assert collection.id == target_collection.id
    end
  end

  describe "update_file_collection/2" do
    test "when give id does not exist" do
      account = %Account{id: UUID.generate()}

      identifiers = %{id: UUID.generate()}
      opts = %{account: account}

      {:error, error} = Service.update_file_collection(identifiers, %{}, opts)

      assert error == :not_found
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()
      collection = file_collection_fixture(account2)

      identifiers = %{id: collection.id}
      opts = %{account: account1}

      {:error, error} = Service.update_file_collection(identifiers, %{}, opts)

      assert error == :not_found
    end

    test "when given valid id and invalid fields" do
      account = account_fixture()
      collection = file_collection_fixture(account)

      identifiers = %{id: collection.id}
      fields = %{"status" => nil}
      opts = %{account: account}

      {:error, %{errors: errors}} = Service.update_file_collection(identifiers, fields, opts)

      assert match_keys(errors, [:status])
    end

    test "when given valid id and valid fields" do
      account = account_fixture()
      target_collection = file_collection_fixture(account)

      identifiers = %{id: target_collection.id}
      fields = %{"name" => Faker.Commerce.product_name()}
      opts = %{account: account}

      {:ok, collection} = Service.update_file_collection(identifiers, fields, opts)

      assert collection.name == fields["name"]
    end
  end

  describe "delete_file_collection/2" do
    test "when give id does not exist" do
      account = %Account{id: UUID.generate()}

      identifiers = %{id: UUID.generate()}
      opts = %{account: account}

      {:error, error} = Service.delete_file_collection(identifiers, opts)

      assert error == :not_found
    end

    test "when given id belongs to a different account" do
      account1 = account_fixture()
      account2 = account_fixture()
      collection = file_collection_fixture(account2)

      identifiers = %{id: collection.id}
      opts = %{account: account1}

      {:error, error} = Service.delete_file_collection(identifiers, opts)

      assert error == :not_found
    end

    test "when given valid id" do
      account = account_fixture()
      collection = file_collection_fixture(account)

      {:ok, collection} = Service.delete_file_collection(%{id: collection.id}, %{account: account})

      assert collection
      refute Repo.get(FileCollection, collection.id)
    end
  end

  describe "delete_file_collection_membership/2" do
    test "when given valid id" do
      account = account_fixture()
      collection = file_collection_fixture(account)
      file = file_fixture(account)
      membership = file_collection_membership_fixture(account, collection, file)

      identifiers = %{id: membership.id}
      opts = %{account: account}

      {:ok, _} = Service.delete_file_collection_membership(identifiers, opts)

      refute Repo.get(FileCollection, membership.id)
    end
  end
end
