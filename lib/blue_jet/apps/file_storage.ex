defmodule BlueJet.FileStorage do
  use BlueJet, :context

  def list_file(req), do: list("file", req)
  def create_file(req), do: create("file", req)
  def get_file(req), do: get("file", req)
  def update_file(req), do: update("file", req)
  def delete_file(req), do: delete("file", req)

  def list_file_collection(req), do: list("file_collection", req)
  def create_file_collection(req), do: create("file_collection", req)
  def get_file_collection(req), do: get("file_collection", req)
  def update_file_collection(req), do: update("file_collection", req)
  def delete_file_collection(req), do: delete("file_collection", req)

  def create_file_collection_membership(req), do: create("file_collection_membership", req)
  def update_file_collection_membership(req), do: update("file_collection_membership", req)
  def delete_file_collection_membership(req), do: delete("file_collection_membership", req)
end
