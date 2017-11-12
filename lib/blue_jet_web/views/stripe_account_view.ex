defmodule BlueJetWeb.StripeAccountView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :stripe_user_id,
    :stripe_livemode,
    :stripe_access_token,
    :stripe_refresh_token,
    :stripe_publishable_key,
    :stripe_scope,
    :locale,
    :inserted_at,
    :updated_at
  ]

  def type(_, _) do
    "StripeAccount"
  end

  def locale(_, %{ assigns: %{ locale: locale } }), do: locale
end
