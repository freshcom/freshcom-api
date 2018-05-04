defmodule BlueJet.DataTrading do
  use BlueJet, :context

  alias BlueJet.DataTrading.{Policy, Service}

  def create_data_import(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "create_data_import") do
      do_create_data_import(authorize_args)
    else
      other -> other
    end
  end

  def do_create_data_import(args) do
    with {:ok, _} <- Service.create_data_import(args[:fields], args[:opts]) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end
end