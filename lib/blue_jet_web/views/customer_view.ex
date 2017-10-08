defmodule BlueJetWeb.CustomerView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :code,
    :status,
    :first_name,
    :last_name,
    :email,
    :encrypted_password,
    :label,
    :display_name,
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

  has_one :refresh_token, serializer: BlueJetWeb.RefreshTokenView, identifiers: :when_included

  def type(_, _) do
    "Customer"
  end

  def locale(_, %{ assigns: %{ locale: locale } }), do: locale
end
