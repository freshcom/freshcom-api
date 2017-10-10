defmodule BlueJetWeb.UnlockView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [:inserted_at, :updated_at]

  has_one :unlockable, serializer: BlueJetWeb.UnlockableView, identifiers: :when_included

  def locale(_, %{ assigns: %{ locale: locale } }), do: locale

  def type(_, _) do
    "Unlock"
  end
end
