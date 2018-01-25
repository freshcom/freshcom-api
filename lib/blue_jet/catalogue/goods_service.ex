defmodule BlueJet.Catalogue.GoodsService do
  alias BlueJet.Goods.{Stockable, Unlockable, Depositable}

  @goods_service Application.get_env(:blue_jet, :catalogue)[:goods_service]

  @callback get_goods(String.t, String.t) :: Stockable.t | Unlockable.t | Depositable.t

  defdelegate get_goods(type, id), to: @goods_service
end