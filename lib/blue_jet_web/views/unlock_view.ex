defmodule BlueJetWeb.UnlockView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [:inserted_at, :updated_at]

  has_one :unlockable, serializer: BlueJetWeb.UnlockableView, identifiers: :always

  def type do
    "Unlock"
  end

  def unlockable(%{ unlockable_id: nil }, _), do: nil
  def unlockable(%{ unlockable_id: unlockable_id, unlockable: nil }, _), do: %{ id: unlockable_id, type: "ExternalFile" }
  def unlockable(%{ unlockable: unlockable }, _), do: unlockable
end
