defmodule BlueJetWeb.CardView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  alias BlueJet.Repo

  attributes [
    :status,
    :last_four_digit,
    :exp_month,
    :exp_year,
    :fingerprint,
    :cardholder_name,
    :brand,
    :country,
    :stripe_card_id,
    :primary,
    :inserted_at,
    :updated_at
  ]

  has_one :owner, serializer: BlueJetWeb.IdentifierView, identifiers: :always

  def type(_, _) do
    "Card"
  end

  def locale(_, %{ assigns: %{ locale: locale } }), do: locale

  def owner(struct, _) do
    %{
      id: struct.owner_id,
      type: struct.owner_type
    }
  end
end
