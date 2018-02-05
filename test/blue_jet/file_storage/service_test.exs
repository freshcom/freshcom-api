defmodule BlueJet.FileStorage.ServiceTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.Account
  alias BlueJet.FileStorage.File
  alias BlueJet.FileStorage.Service

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

      files = Service.list_file(%{ account: account })
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

      files = Service.list_file(%{ account: account, pagination: %{ size: 3, number: 1 } })
      assert length(files) == 3

      files = Service.list_file(%{ account: account, pagination: %{ size: 3, number: 2 } })
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

      assert Service.count_file(%{ account: account }) == 2
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

      assert Service.count_file(%{ filter: %{ label: "test" } }, %{ account: account }) == 1
    end
  end

  describe "create_file/2" do
    test "when given valid fields" do
      account = Repo.insert!(%Account{})

      fields = %{
        "name" => Faker.String.base64(5),
        "content_type" => "image/png",
        "size_bytes" => 19203
      }

      {:ok, file} = Service.create_file(fields, %{ account: account })

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

      assert Service.get_file(%{ id: file.id }, %{ account: account })
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

      refute Service.get_file(%{ id: file.id }, %{ account: account })
    end

    test "when give id does not exist" do
      account = Repo.insert!(%Account{})

      refute Service.get_file(%{ id: Ecto.UUID.generate() }, %{ account: account })
    end
  end

  describe "update_file/2" do
    test "when given nil for file" do
      {:error, error} = Service.update_file(nil, %{}, %{})
      assert error == :not_found
    end

    test "when given id does not exist" do
      account = Repo.insert!(%Account{})

      {:error, error} = Service.update_file(Ecto.UUID.generate(), %{}, %{ account: account })
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

      {:error, error} =Service.update_file(file.id, %{}, %{ account: account })
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

      {:error, changeset} = Service.update_file(file.id, %{ "status" => nil }, %{ account: account })
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

      fields = %{
        "status" => "uploaded"
      }

      {:ok, file} = Service.update_file(file.id, fields, %{ account: account })
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

      {:error, changeset} = Service.update_file(file, %{ "status" => nil }, %{ account: account })
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

      fields = %{
        "status" => "uploaded"
      }

      {:ok, file} = Service.update_file(file, fields, %{ account: account })
      assert file
    end
  end
end
