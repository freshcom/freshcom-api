defmodule BlueJet.Goods do
  use BlueJet, :context

  @policy BlueJet.Goods.Policy
  @service BlueJet.Goods.Service

  def list_stockable(req), do: default(req, :list, :stockable, @policy, @service)
  def create_stockable(req), do: default(req, :create, :stockable, @policy, @service)
  def get_stockable(req), do: default(req, :get, :stockable, @policy, @service)
  def update_stockable(req), do: default(req, :update, :stockable, @policy, @service)
  def delete_stockable(req), do: default(req, :delete, :stockable, @policy, @service)

  def list_unlockable(req), do: default(req, :list, :unlockable, @policy, @service)
  def create_unlockable(req), do: default(req, :create, :unlockable, @policy, @service)
  def get_unlockable(req), do: default(req, :get, :unlockable, @policy, @service)
  def update_unlockable(req), do: default(req, :update, :unlockable, @policy, @service)
  def delete_unlockable(req), do: default(req, :delete, :unlockable, @policy, @service)

  def list_depositable(req), do: default(req, :list, :depositable, @policy, @service)
  def create_depositable(req), do: default(req, :create, :depositable, @policy, @service)
  def get_depositable(req), do: default(req, :get, :depositable, @policy, @service)
  def update_depositable(req), do: default(req, :update, :depositable, @policy, @service)
  def delete_depositable(req), do: default(req, :delete, :depositable, @policy, @service)
end
