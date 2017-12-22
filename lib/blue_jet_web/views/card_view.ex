defmodule BlueJetWeb.CardView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :status,
    :code,
    :name,
    :label,

    :last_four_digit,
    :exp_month,
    :exp_year,
    :fingerprint,
    :cardholder_name,
    :brand,
    :country,
    :stripe_card_id,
    :primary,

    :caption,
    :description,
    :custom_data,

    :inserted_at,
    :updated_at
  ]

  has_one :owner, serializer: BlueJetWeb.IdentifierView, identifiers: :always

  def type do
    "Card"
  end

  def owner(struct, _) do
    %{
      id: struct.owner_id,
      type: struct.owner_type
    }
  end
end
