defmodule BlueJetWeb.AccountMembershipView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :account_name,
    :user_name,
    :user_username,
    :user_email,
    :role,
    :user_kind,
    :inserted_at,
    :updated_at
  ]

  has_one :user, serializer: BlueJetWeb.IdentifierView, identifiers: :always

  def type do
    "AccountMembership"
  end

  def role(membership) do
    Inflex.camelize(membership.role, :lower)
  end

  def user_kind(membership) do
    if membership.user.account_id, do: "managed", else: "standard"
  end

  def account_name(membership) do
    membership.account.name
  end

  def user_name(membership) do
    membership.user.name
  end

  def user_username(membership) do
    membership.user.username
  end

  def user_email(membership) do
    membership.user.email
  end

  def user(%{ user_id: user_id }, _), do: %{ id: user_id, type: "User" }
end
