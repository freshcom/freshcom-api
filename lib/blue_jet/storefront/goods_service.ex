defmodule BlueJet.Storefront.GoodsService do
  alias BlueJet.Goods.{Stockable, Unlockable, Depositable}

  @goods_service Application.get_env(:blue_jet, :storefront)[:goods_service]

  @callback get_goods(String.t, String.t) :: Stockable.t | Unlockable.t | Depositable.t
  @callback get_depositable(String.t) :: Depositable.t
  @callback get_unlockable(String.t) :: Unlockable.t

  defdelegate get_goods(type, id), to: @goods_service
  defdelegate get_depositable(id), to: @goods_service
  defdelegate get_unlockable(id), to: @goods_service
end