defmodule BlueJet.DataTrading do
  use BlueJet, :context

  def create_data_import(req), do: create("data_import", req)
end