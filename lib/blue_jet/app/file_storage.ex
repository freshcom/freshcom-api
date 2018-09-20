defmodule BlueJet.FileStorage do
  use BlueJet, :context

  alias BlueJet.FileStorage.{Policy, Service}

  def list_file(req), do: default(req, :list, :file, Policy, Service)
  def create_file(req), do: default(req, :create, :file, Policy, Service)
  def get_file(req), do: default(req, :get, :file, Policy, Service)
  def update_file(req), do: default(req, :update, :file, Policy, Service)
  def delete_file(req), do: default(req, :delete, :file, Policy, Service)

  def list_file_collection(req), do: default(req, :list, :file_collection, Policy, Service)
  def create_file_collection(req), do: default(req, :create, :file_collection, Policy, Service)
  def get_file_collection(req), do: default(req, :get, :file_collection, Policy, Service)
  def update_file_collection(req), do: default(req, :update, :file_collection, Policy, Service)
  def delete_file_collection(req), do: default(req, :delete, :file_collection, Policy, Service)

  def list_file_collection_membership(req), do: default(req, :list, :file_collection_membership, Policy, Service)
  def create_file_collection_membership(req), do: default(req, :create, :file_collection_membership, Policy, Service)
  def get_file_collection_membership(req), do: default(req, :get, :file_collection_membership, Policy, Service)
  def update_file_collection_membership(req), do: default(req, :update, :file_collection_membership, Policy, Service)
  def delete_file_collection_membership(req), do: default(req, :delete, :file_collection_membership, Policy, Service)
end
