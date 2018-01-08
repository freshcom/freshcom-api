defmodule BlueJet.Notification.Email do
  use BlueJet, :data

  alias BlueJet.Identity.User

  schema "emails" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string, default: "pending"

    field :recipient_email, :string
    field :sender_email, :string

    field :content, :string

    timestamps()

    belongs_to :recipient, User
    belongs_to :trigger, NotificationTrigger
    belongs_to :template, EmailTemplate
  end

  def system_fields do
    [
      :id,
      :account_id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    __MODULE__.__schema__(:fields) -- system_fields()
  end

  def castable_fields(_) do
    []
  end

  defmodule Query do
    use BlueJet, :query

    alias BlueJet.Notification.Email

    def default() do
      from(e in Email, order_by: [desc: :updated_at])
    end

    def for_account(query, account_id) do
      from(e in query, where: e.account_id == ^account_id)
    end

    def preloads(_, _) do
      []
    end
  end
end
