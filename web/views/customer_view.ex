defmodule BlueJet.CustomerView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  attributes [:first_name, :last_name, :email, :encrypted_password, :display_name, :custom_data, :inserted_at, :updated_at]

  has_one :refresh_token, serializer: BlueJet.RefreshTokenView, identifiers: :when_included
end
