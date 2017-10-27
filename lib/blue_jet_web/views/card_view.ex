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
    :stripe_card_id,
    :inserted_at,
    :updated_at
  ]

  has_one :customer, serializer: BlueJetWeb.CustomerView, identifiers: :always

  def type(_, _) do
    "Card"
  end

  def locale(_, %{ assigns: %{ locale: locale } }), do: locale

  def customer(struct, conn) do
    case struct.customer do
      %Ecto.Association.NotLoaded{} ->
        struct
        |> Ecto.assoc(:customer)
        |> Repo.one()
      other -> other
    end
  end
end
