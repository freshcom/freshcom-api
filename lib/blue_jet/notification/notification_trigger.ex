defmodule BlueJet.Notification.NotificationTrigger do
  use BlueJet, :data

  alias Bamboo.Email, as: E
  alias BlueJet.AccountMailer

  alias BlueJet.Notification.EmailTemplate

  schema "notification_triggers" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string, default: "active"
    field :name, :string
    field :system_label, :string

    field :event, :string
    field :description, :string

    field :action_target, :string
    field :action_type, :string # sendEmail, invokeWebhook, sendSMS

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

  def castable_fields() do
    [:event, :name, :description, :action_target, :action_type]
  end

  def validate(changeset) do
    changeset
    |> validate_required([:account_id, :name, :event, :action_target, :action_type])
    |> foreign_key_constraint(:account_id)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, castable_fields())
    |> validate()
  end

  def process(
    %{ event: event, action_type: "send_email", action_target: template_id },
    data = %{ account: account, user: user })
  do
    template = Repo.get_by(EmailTemplate, account_id: account.id, id: template_id)
    template_variables = EmailTemplate.extract_variables(event, data)

    html_body = EmailTemplate.render_html(template, template_variables)
    text_body = EmailTemplate.render_text(template, template_variables)
    subject = EmailTemplate.render_subject(template, template_variables)
    to = EmailTemplate.render_to(template, template_variables)

    E.new_email()
    |> E.to("roy@freshcom.io")
    |> E.from({account.name, "support@freshcom.io"})
    |> E.html_body(html_body)
    |> E.text_body(text_body)
    |> E.subject(subject)
    |> AccountMailer.deliver_later()
  end

  def process(trigger, _) do
    {:ok, trigger}
  end

  defmodule AccountDefault do
    alias BlueJet.Notification.NotificationTrigger

    def send_password_reset_email(account, email_template) do
      %NotificationTrigger{
        account_id: account.id,
        system_label: "default",
        name: "Send password reset email",
        event: "identity.password_reset_token.created",
        action_type: "send_email",
        action_target: email_template.id
      }
    end

    def send_email_confirmation_email(account, email_template) do
      %NotificationTrigger{
        account_id: account.id,
        system_label: "default",
        name: "Send email confirmation email",
        event: "identity.user.created",
        action_type: "send_email",
        action_target: email_template.id
      }
    end
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

    def for_event(query, event) do
      from(nt in query, where: nt.event == ^event)
    end

    def preloads(_, _) do
      []
    end
  end
end
