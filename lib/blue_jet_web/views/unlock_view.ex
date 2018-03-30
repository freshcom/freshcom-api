defmodule BlueJetWeb.UnlockView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [:inserted_at, :updated_at]

  has_one :unlockable, serializer: BlueJetWeb.UnlockableView, identifiers: :always
  has_one :customer, serializer: BlueJetWeb.CustomerView, identifiers: :always

  def type do
    "Unlock"
  end

  def unlockable(%{ unlockable_id: nil }, _), do: nil
  def unlockable(%{ unlockable_id: unlockable_id, unlockable: nil }, _), do: %{ id: unlockable_id, type: "Unlockable" }
  def unlockable(%{ unlockable: unlockable }, _), do: unlockable

  def customer(%{ customer_id: nil }, _), do: nil
  def customer(%{ customer_id: customer_id, customer: nil }, _), do: %{ id: customer_id, type: "Customer" }
  def customer(%{ customer: customer }, _), do: customer
end
