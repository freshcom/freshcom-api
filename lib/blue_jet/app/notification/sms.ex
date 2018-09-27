defmodule BlueJet.Notification.SMS do
  use BlueJet, :data

  alias BlueJet.Identity.User
  alias BlueJet.Notification.{Trigger, SMSTemplate}

  schema "sms" do
    field :account_id, UUID
    field :account, :map, virtual: true

    field :status, :string, default: "sent"

    field :to, :string
    field :body, :string
    field :locale, :string

    timestamps()

    belongs_to :recipient, User
    belongs_to :trigger, Trigger
    belongs_to :template, SMSTemplate
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

  def translatable_fields do
    []
  end
end
