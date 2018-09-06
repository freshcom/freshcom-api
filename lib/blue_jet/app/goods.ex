defmodule BlueJet.Goods do
  use BlueJet, :context

  def list_stockable(req), do: list("stockable", req, __MODULE__)
  def create_stockable(req), do: create("stockable", req, __MODULE__)
  def get_stockable(req), do: get("stockable", req, __MODULE__)
  def update_stockable(req), do: update("stockable", req, __MODULE__)
  def delete_stockable(req), do: delete("stockable", req, __MODULE__)

  def list_unlockable(req), do: list("unlockable", req, __MODULE__)
  def create_unlockable(req), do: create("unlockable", req, __MODULE__)
  def get_unlockable(req), do: get("unlockable", req, __MODULE__)
  def update_unlockable(req), do: update("unlockable", req, __MODULE__)
  def delete_unlockable(req), do: delete("unlockable", req, __MODULE__)

  def list_depositable(req), do: list("depositable", req, __MODULE__)
  def create_depositable(req), do: create("depositable", req, __MODULE__)
  def get_depositable(req), do: get("depositable", req, __MODULE__)
  def update_depositable(req), do: update("depositable", req, __MODULE__)
  def delete_depositable(req), do: delete("depositable", req, __MODULE__)
end
