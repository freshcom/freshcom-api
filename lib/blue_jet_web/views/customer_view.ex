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
  has_one :user, serializer: BlueJetWeb.IdentifierView, identifiers: :always
  has_one :point_account, serializer: BlueJetWeb.PointAccountView, identifiers: :when_included

  has_many :file_collections, serializer: BlueJetWeb.FileCollectionView, identifiers: :when_included
  has_many :cards, serializer: BlueJetWeb.CardView, identifiers: :when_included

  def type do
    "Customer"
  end

  def enroller(%{ enroller_id: nil }, _), do: nil
  def enroller(%{ enroller_id: enroller_id, enroller: %Ecto.Association.NotLoaded{} }, _), do: %{ id: enroller_id, type: "Customer" }
  def enroller(%{ enroller: enroller }, _), do: enroller

  def sponsor(%{ sponsor_id: nil }, _), do: nil
  def sponsor(%{ sponsor_id: sponsor_id, sponsor: %Ecto.Association.NotLoaded{} }, _), do: %{ id: sponsor_id, type: "Customer" }
  def sponsor(%{ sponsor: sponsor }, _), do: sponsor

  def user(%{ user_id: nil }, _), do: nil
  def user(%{ user_id: user_id, user: nil }, _), do: %{ id: user_id, type: "User" }
  def user(%{ user: user }, _), do: user
end
