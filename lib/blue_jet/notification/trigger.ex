defmodule BlueJet.Notification.Trigger do
  use BlueJet, :data

  alias Bamboo.Email, as: E
  alias BlueJet.AccountMailer

  alias BlueJet.Notification.EmailTemplate
  alias BlueJet.Notification.Trigger.Proxy

  schema "notification_triggers" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string, default: "active"
    field :name, :string
    field :system_label, :string

    field :event, :string
    field :description, :string

    field :action_target, :string
    field :action_type, :string # send_email, invoke_webhook, send_sms

    timestamps()
  end

  @type t :: Ecto.Schema.t

  @system_fields [
    :id,
    :account_id,
    :system_label,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  def validate(changeset) do
    changeset
    |> validate_required([:name, :status, :event, :action_target, :action_type])
  end

  def changeset(trigger, :insert, params) do
    trigger
    |> cast(params, writable_fields())
    |> validate()
  end

  def changeset(trigger, :delete) do
    change(trigger)
    |> Map.put(:action, :delete)
  end

  def fire_action(
    trigger = %{ event: event, action_type: "send_email", action_target: template_id },
    data
  ) do
    account = Proxy.get_account(trigger)
    data = Map.put(data, :account, account)

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

  def fire_action(trigger, _) do
    {:ok, trigger}
  end

  defmodule AccountDefault do
    alias BlueJet.Notification.Trigger

    def send_password_reset_email(account, email_template) do
      %Trigger{
        account_id: account.id,
        system_label: "default",
        name: "Send password reset email",
        event: "identity.password_reset_token.create.success",
        action_type: "send_email",
        action_target: email_template.id
      }
    end

    def send_password_reset_not_registered_email(account, email_template) do
      %Trigger{
        account_id: account.id,
        system_label: "default",
        name: "Send password reset not registered email",
        event: "identity.password_reset_token.create.error.email_not_found",
        action_type: "send_email",
        action_target: email_template.id
      }
    end

    def send_email_confirmation_email(account, email_template) do
      %Trigger{
        account_id: account.id,
        system_label: "default",
        name: "Send email confirmation email",
        event: "identity.email_confirmation_token.create.success",
        action_type: "send_email",
        action_target: email_template.id
      }
    end
  end
end
