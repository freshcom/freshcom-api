defmodule BlueJet.Notification.Sms do
  use BlueJet, :data

  alias BlueJet.Identity.User
  alias BlueJet.Notification.{Trigger, SmsTemplate}

  schema "sms" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string, default: "sent"

    field :to, :string
    field :body, :string
    field :locale, :string

    timestamps()

    belongs_to :recipient, User
    belongs_to :trigger, Trigger
    belongs_to :template, SmsTemplate
  end

  @type t :: Ecto.Schema.t()

  @system_fields [
    :id,
    :account_id,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end
end
