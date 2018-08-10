defmodule BlueJetWeb.AccountMembershipView do
  use BlueJetWeb, :view
  use JaSerializer.PhoenixView

  attributes [
    :account_name,
    :user_name,
    :user_username,
    :user_email,
    :role,
    :inserted_at,
    :updated_at
  ]

  def type do
    "AccountMembership"
  end

  def account_name(membership, _) do
    membership.account.name
  end

  def user_name(membership, _) do
    membership.user.name
  end

  def user_username(membership, _) do
    membership.user.username
  end

  def user_email(membership, _) do
    membership.user.email
  end
end
