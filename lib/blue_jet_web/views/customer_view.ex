defmodule BlueJetWeb.CustomerView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  alias BlueJet.Storefront.Customer

  attributes [
    :code,
    :status,
    :first_name,
    :last_name,
    :email,
    :label,
    :other_name,
    :phone_number,
    :delivery_address_line_one,
    :delivery_address_line_two,
    :delivery_address_province,
    :delivery_address_city,
    :delivery_address_country_code,
    :delivery_address_postal_code,
    :custom_data,
    :locale,
    :inserted_at,
    :updated_at
  ]

  has_one :enroller, serializer: BlueJetWeb.CustomerView, identifiers: :always
  has_one :sponsor, serializer: BlueJetWeb.CustomerView, identifiers: :always

  has_one :refresh_token, serializer: BlueJetWeb.RefreshTokenView, identifiers: :when_included
  has_one :point_account, serializer: BlueJetWeb.PointAccountView, identifiers: :when_included

  has_many :unlocks, serializer: BlueJetWeb.UnlockView, identifiers: :when_included
  has_many :orders, serializer: BlueJetWeb.OrderView, identifiers: :when_included
  has_many :cards, serializer: BlueJetWeb.CardView, identifiers: :when_included

  def type(_, _) do
    "Customer"
  end

  def locale(_, %{ assigns: %{ locale: locale } }), do: locale

  def enroller(customer = %{ enroller: %Ecto.Association.NotLoaded{} }, _) do
    case customer.enroller_id do
      nil -> nil
      _ -> %{ type: "Customer", id: customer.enroller_id }
    end
  end
  def enroller(customer, _), do: Map.get(customer, :enroller)

  def sponsor(customer = %{ sponsor: %Ecto.Association.NotLoaded{} }, _) do
    case customer.sponsor_id do
      nil -> nil
      _ -> %{ type: "Customer", id: customer.sponsor_id }
    end
  end
  def sponsor(customer, _), do: Map.get(customer, :spnosor)

end
