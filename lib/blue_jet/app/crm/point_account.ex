defmodule BlueJet.CRM.PointAccount do
  use BlueJet, :data

  alias BlueJet.CRM.{PointTransaction, Customer}

  schema "point_accounts" do
    field :account_id, UUID
    field :account, :map, virtual: true

    field :status, :string, default: "active"
    field :balance, :integer, default: 0

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :customer, Customer
    has_many :transactions, PointTransaction
  end
end
