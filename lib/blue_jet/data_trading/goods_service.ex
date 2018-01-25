defmodule BlueJet.DataTrading.GoodsService do
  alias BlueJet.Goods.Unlockable

  @goods_service Application.get_env(:blue_jet, :data_trading)[:goods_service]

  @callback get_unlockable(String.t, map) :: Unlockable.t | nil
  @callback get_unlockable_by_code(String.t, map) :: Unlockable.t | nil
  @callback create_unlockable(map, map) :: {:ok, Unlockable.t} | {:error, any}
  @callback update_unlockable(String.t, map, map) :: {:ok, Unlockable.t} | {:error, any}

  defdelegate get_unlockable(id, opts), to: @goods_service
  defdelegate get_unlockable_by_code(code, opts), to: @goods_service
  defdelegate create_unlockable(fields, opts), to: @goods_service
  defdelegate update_unlockable(id, fields, opts), to: @goods_service
end