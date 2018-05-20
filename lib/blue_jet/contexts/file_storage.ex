defmodule BlueJet.FileStorage do
  use BlueJet, :context

  def list_file(req), do: list("file", req, __MODULE__)
  def create_file(req), do: create("file", req, __MODULE__)
  def get_file(req), do: get("file", req, __MODULE__)
  def update_file(req), do: update("file", req, __MODULE__)
  def delete_file(req), do: delete("file", req, __MODULE__)

  def list_file_collection(req), do: list("file_collection", req, __MODULE__)
  def create_file_collection(req), do: create("file_collection", req, __MODULE__)
  def get_file_collection(req), do: get("file_collection", req, __MODULE__)
  def update_file_collection(req), do: update("file_collection", req, __MODULE__)
  def delete_file_collection(req), do: delete("file_collection", req, __MODULE__)

  def create_file_collection_membership(req), do: create("file_collection_membership", req, __MODULE__)
  def update_file_collection_membership(req), do: update("file_collection_membership", req, __MODULE__)
  def delete_file_collection_membership(req), do: delete("file_collection_membership", req, __MODULE__)
end
