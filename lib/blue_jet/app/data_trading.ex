defmodule BlueJet.DataTrading do
  use BlueJet, :context

  alias BlueJet.DataTrading.{Policy, Service}

  def create_data_import(req), do: default(req, :create, :data_import, Policy, Service)
end