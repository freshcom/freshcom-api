defmodule BlueJet.Storefront.GoodsData do
  alias BlueJet.Goods.{Stockable, Unlockable, Depositable}

  @goods_data Application.get_env(:blue_jet, :storefront)[:goods_data]

  @callback get_goods(String.t, String.t) :: Stockable.t | Unlockable.t | Depositable.t
  @callback get_depositable(String.t) :: Depositable.t
  @callback get_unlockable(String.t) :: Unlockable.t

  defdelegate get_goods(type, id), to: @goods_data
  defdelegate get_depositable(id), to: @goods_data
  defdelegate get_unlockable(id), to: @goods_data
end