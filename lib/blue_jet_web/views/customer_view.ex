defmodule BlueJetWeb.CustomerView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :status,
    :code,
    :name,
    :label,

    :first_name,
    :last_name,
    :email,
    :phone_number,

    :delivery_address_line_one,
    :delivery_address_line_two,
    :delivery_address_province,
    :delivery_address_city,
    :delivery_address_country_code,
    :delivery_address_postal_code,

    :caption,
    :description,
    :custom_data,

    :inserted_at,
    :updated_at
  ]

  has_one :enroller, serializer: BlueJetWeb.CustomerView, identifiers: :always
  has_one :sponsor, serializer: BlueJetWeb.CustomerView, identifiers: :always

  # has_one :refresh_token, serializer: BlueJetWeb.RefreshTokenView, identifiers: :when_included
  has_one :point_account, serializer: BlueJetWeb.PointAccountView, identifiers: :when_included

  has_many :unlocks, serializer: BlueJetWeb.UnlockView, identifiers: :when_included
  has_many :orders, serializer: BlueJetWeb.OrderView, identifiers: :when_included
  has_many :cards, serializer: BlueJetWeb.CardView, identifiers: :when_included

  def type do
    "Customer"
  end

  def enroller(%{ enroller_id: nil }, _), do: nil

  def enroller(%{ enroller_id: enroller_id, enroller: %Ecto.Association.NotLoaded{} }, _) do
    %{ id: enroller_id, type: "Customer" }
  end

  def enroller(%{ enroller: enroller }, _), do: enroller

  def sponsor(%{ sponsor_id: nil }, _), do: nil

  def sponsor(%{ sponsor_id: sponsor_id, sponsor: %Ecto.Association.NotLoaded{} }, _) do
    %{ id: sponsor_id, type: "Customer" }
  end

  def sponsor(%{ sponsor: sponsor }, _), do: sponsor

end
