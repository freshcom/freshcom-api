defmodule BlueJet.Catalogue.GoodsData do
  alias BlueJet.Goods.{Stockable, Unlockable, Depositable}

  @goods_data Application.get_env(:blue_jet, :catalogue)[:goods_data]

  @callback get_goods(String.t, String.t) :: Stockable.t | Unlockable.t | Depositable.t

  defdelegate get_goods(type, id), to: @goods_data
end