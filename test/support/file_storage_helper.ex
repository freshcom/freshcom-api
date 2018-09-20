defmodule BlueJet.FileStorage.TestHelper do
  alias BlueJet.FileStorage.Service

  def file_fixture(account, fields \\ %{}) do
    default_fields = %{
      name: Faker.File.file_name(),
      content_type: Faker.File.mime_type(),
      size_bytes: System.unique_integer([:positive])
    }
    fields = Map.merge(default_fields, fields)

    {:ok, file} = Service.create_file(fields, %{account: account})

    file
  end

  def file_collection_fixture(account, fields \\ %{}) do
    default_fields = %{name: Faker.Commerce.product_name()}
    fields = Map.merge(default_fields, fields)

    {:ok, collection} = Service.create_file_collection(fields, %{account: account})

    collection
  end

  def file_collection_membership_fixture(account, collection, file, fields \\ %{}) do
    default_fields = %{
      collection_id: collection.id,
      file_id: file.id
    }
    fields = Map.merge(default_fields, fields)

    {:ok, membership} = Service.create_file_collection_membership(fields, %{account: account})

    membership
  end
end
