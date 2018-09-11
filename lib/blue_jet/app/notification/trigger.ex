defmodule BlueJet.Notification.Trigger do
  use BlueJet, :data

  alias Bamboo.Email, as: E
  alias BlueJet.AccountMailer

  alias BlueJet.Notification.{Email, EmailTemplate, Sms, SmsTemplate}

  schema "notification_triggers" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string, default: "active"
    field :name, :string
    field :system_label, :string

    field :event, :string
    field :description, :string

    field :action_target, :string
    # send_email, invoke_webhook, send_sms
    field :action_type, :string

    timestamps()
  end

  @type t :: Ecto.Schema.t()

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

  def translatable_fields do
    []
  end

  @spec changeset(__MODULE__.t(), atom, map) :: Changeset.t()
  def changeset(trigger, :insert, fields) do
    trigger
    |> cast(fields, castable_fields(:insert))
    |> Map.put(:action, :insert)
    |> validate()
  end

  def changeset(trigger, :update, fields) do
    trigger
    |> cast(fields, castable_fields(:update))
    |> Map.put(:action, :update)
    |> validate()
  end

  @spec changeset(__MODULE__.t(), atom) :: Changeset.t()
  def changeset(trigger, :delete) do
    change(trigger)
    |> Map.put(:action, :delete)
  end

  def changeset(trigger, :update, fields, _), do: changeset(trigger, :update, fields)

  @spec validate(Changeset.t()) :: Changeset.t()
  def validate(changeset) do
    changeset
    |> validate_required([:name, :status, :event, :action_type, :action_target])
  end

  defp castable_fields(:insert) do
    writable_fields()
  end

  defp castable_fields(:update) do
    writable_fields() -- [:event, :action_type]
  end

  @spec fire_action(__MODULE__.t(), map) :: map
  def fire_action(
        trigger = %{event: event, action_type: "send_email", action_target: template_id},
        data
      ) do
    account = data[:account]

    template = Repo.get_by(EmailTemplate, account_id: account.id, id: template_id)
    template_variables = EmailTemplate.extract_variables(event, data)

    html_body = EmailTemplate.render_html(template, template_variables)
    text_body = EmailTemplate.render_text(template, template_variables)
    subject = EmailTemplate.render_subject(template, template_variables)
    to = EmailTemplate.render_to(template, template_variables)

    bamboo_email =
      E.new_email()
      |> E.to(to)
      |> E.from({account.name, "support@freshcom.io"})
      |> E.html_body(html_body)
      |> E.text_body(text_body)
      |> E.subject(subject)
      |> AccountMailer.deliver_later()

    Repo.insert!(%Email{
      account_id: account.id,
      trigger_id: trigger.id,
      template_id: template.id,
      status: "sent",
      subject: bamboo_email.subject,
      from: E.get_address(bamboo_email.from),
      to: E.get_address(Enum.at(bamboo_email.to, 0)),
      body_html: bamboo_email.html_body,
      body_text: bamboo_email.text_body,
      locale: account.default_locale
    })
  end

  def fire_action(
        trigger = %{event: event, action_type: "send_sms", action_target: template_id},
        data
      ) do
    account = data[:account]

    template = Repo.get_by(SmsTemplate, account_id: account.id, id: template_id)
    template_variables = SmsTemplate.extract_variables(event, data)

    to = SmsTemplate.render_to(template, template_variables)
    body = SmsTemplate.render_body(template, template_variables)

    ExAws.SNS.publish(body, phone_number: to)
    |> ExAws.request()

    Repo.insert!(%Sms{
      account_id: account.id,
      trigger_id: trigger.id,
      template_id: template.id,
      status: "sent",
      to: to,
      body: body,
      locale: account.default_locale
    })
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
        event: "identity:password_reset_token.create.success",
        action_type: "send_email",
        action_target: email_template.id
      }
    end

    def send_password_reset_not_registered_email(account, email_template) do
      %Trigger{
        account_id: account.id,
        system_label: "default",
        name: "Send password reset not registered email",
        event: "identity:password_reset_token.create.error.username_not_found",
        action_type: "send_email",
        action_target: email_template.id
      }
    end

    def send_email_verification_email(account, email_template) do
      %Trigger{
        account_id: account.id,
        system_label: "default",
        name: "Send email confirmation email",
        event: "identity:email_verification_token.create.success",
        action_type: "send_email",
        action_target: email_template.id
      }
    end

    def send_order_confirmation_email(account, email_template) do
      %Trigger{
        account_id: account.id,
        system_label: "default",
        name: "Send order confirmation email",
        event: "storefront.order.opened.success",
        action_type: "send_email",
        action_target: email_template.id
      }
    end

    def send_phone_verification_code_sms(account, sms_template) do
      %Trigger{
        account_id: account.id,
        system_label: "default",
        name: "Send phone verification code sms",
        event: "identity:phone_verification_code.create.success",
        action_type: "send_sms",
        action_target: sms_template.id
      }
    end

    def send_tfa_code_sms(account, sms_template) do
      %Trigger{
        account_id: account.id,
        system_label: "default",
        name: "Send TFA code sms",
        event: "identity.user.tfa_code.create.success",
        action_type: "send_sms",
        action_target: sms_template.id
      }
    end
  end
end
