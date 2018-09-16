defmodule BlueJet.Goods do
  use BlueJet, :context

  alias BlueJet.Goods.{Policy, Service}

  def list_stockable(req), do: default(req, :list, :stockable, Policy, Service)
  def create_stockable(req), do: default(req, :create, :stockable, Policy, Service)
  def get_stockable(req), do: default(req, :get, :stockable, Policy, Service)
  def update_stockable(req), do: default(req, :update, :stockable, Policy, Service)
  def delete_stockable(req), do: default(req, :delete, :stockable, Policy, Service)

  def list_unlockable(req), do: default(req, :list, :unlockable, Policy, Service)
  def create_unlockable(req), do: default(req, :create, :unlockable, Policy, Service)
  def get_unlockable(req), do: default(req, :get, :unlockable, Policy, Service)
  def update_unlockable(req), do: default(req, :update, :unlockable, Policy, Service)
  def delete_unlockable(req), do: default(req, :delete, :unlockable, Policy, Service)

  def list_depositable(req), do: default(req, :list, :depositable, Policy, Service)
  def create_depositable(req), do: default(req, :create, :depositable, Policy, Service)
  def get_depositable(req), do: default(req, :get, :depositable, Policy, Service)
  def update_depositable(req), do: default(req, :update, :depositable, Policy, Service)
  def delete_depositable(req), do: default(req, :delete, :depositable, Policy, Service)
end
