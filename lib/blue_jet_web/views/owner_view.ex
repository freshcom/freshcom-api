defmodule BlueJetWeb.OwnerView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  def type(struct, _) do
    struct.type
  end
end
