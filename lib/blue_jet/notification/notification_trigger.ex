defmodule BlueJet.Notification.NotificationTrigger do
  use BlueJet, :data

  alias BlueJet.Notification.Email

  schema "emails" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :name, :string
    field :system_label, :string

    field :endpoint, :string
    field :description, :string

    field :target_id, :string
    field :target_type, :string

    timestamps()
  end

  def system_fields do
    [
      :id,
      :account_id,
      :system_label,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    __MODULE__.__schema__(:fields) -- system_fields()
  end

  def castable_fields(_) do
    [:endpoint, :description, :target_id, :target_type]
  end

  def process(%{ event_id: "password_reset_token.created" }, %{ account: account, user: user }) do

  end

  def process(trigger, _) do
    {:ok, trigger}
  end

  defmodule Query do
    use BlueJet, :query

    alias BlueJet.Notification.NotificationTrigger

    def default() do
      from(nt in NotificationTrigger, order_by: [desc: :updated_at])
    end

    def for_account(query, account_id) do
      from(nt in query, where: nt.account_id == ^account_id)
    end

    def for_event(query, event_id) do
      from(nt in query, where: nt.event_id == ^event_id)
    end

    def preloads(_, _) do
      []
    end
  end
end
