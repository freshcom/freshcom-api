defmodule BlueJet.Notification.EmailTemplate do
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :subject,
    :to,
    :reply_to,
    :content_html,
    :content_text,
    :description
  ], container: :translations

  alias BlueJet.Notification.Email
  alias BlueJet.Notification.IdentityService

  schema "email_templates" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true
    field :system_label, :string

    field :name, :string
    field :subject, :string
    field :to, :string
    field :reply_to, :string
    field :content_html, :string
    field :content_text, :string
    field :description, :string

    field :translations, :map, default: %{}

    timestamps()

    has_many :email, Email, foreign_key: :template_id
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

  def translatable_fields do
    __MODULE__.__trans__(:fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required([:name, :to, :subject, :content_html])
  end

  def changeset(email_template, params, locale \\ nil, default_locale \\ nil) do
    email_template = %{ email_template | account: get_account(email_template) }
    default_locale = default_locale || email_template.account.default_locale
    locale = locale || default_locale

    email_template
    |> cast(params, writable_fields())
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  def get_account(email_template) do
    email_template.account || IdentityService.get_account(email_template)
  end

  def extract_variables("identity.password_reset_token.create.error.email_not_found", %{ account: account, email: email }) do
    %{
      email: email,
      account: Map.take(account, [:name]),
      freshcom_reset_password_url: System.get_env("RESET_PASSWORD_URL")
    }
  end

  def extract_variables("identity.password_reset_token.create.success", %{ account: account, user: user }) do
    %{
      user: Map.take(user, [:id, :password_reset_token, :first_name, :last_name, :name, :email]),
      account: Map.take(account, [:name]),
      freshcom_reset_password_url: System.get_env("RESET_PASSWORD_URL")
    }
  end

  def extract_variables("identity.email_confirmation_token.create.success", %{ account: account, user: user }) do
    %{
      user: Map.take(user, [:id, :email_confirmation_token, :first_name, :last_name, :email]),
      account: Map.take(account, [:name]),
      freshcom_confirm_email_url: System.get_env("CONFIRM_EMAIL_URL")
    }
  end

  def render_html(%{ content_html: content_html }, variables) do
    :bbmustache.render(content_html, variables, key_type: :atom)
  end

  def render_text(%{ content_text: nil }, _) do
    nil
  end

  def render_text(%{ content_text: content_text }, variables) do
    :bbmustache.render(content_text, variables, key_type: :atom)
  end

  def render_subject(%{ subject: subject }, variables) do
    :bbmustache.render(subject, variables, key_type: :atom)
  end

  def render_to(%{ to: to }, variables) do
    :bbmustache.render(to, variables, key_type: :atom)
  end

  defmodule AccountDefault do
    alias BlueJet.Notification.EmailTemplate

    def password_reset(account) do
      password_reset_html = File.read!("lib/blue_jet/notification/email_templates/password_reset.html")
      password_reset_text = File.read!("lib/blue_jet/notification/email_templates/password_reset.txt")

      %EmailTemplate{
        account_id: account.id,
        system_label: "default",
        name: "Password Reset",
        subject: "Reset your password for {{account.name}}",
        to: "{{user.email}}",
        content_html: password_reset_html,
        content_text: password_reset_text
      }
    end

    def password_reset_not_registered(account) do
      password_reset_not_registered_html = File.read!("lib/blue_jet/notification/email_templates/password_reset_not_registered.html")
      password_reset_not_registered_text = File.read!("lib/blue_jet/notification/email_templates/password_reset_not_registered.txt")

      %EmailTemplate{
        account_id: account.id,
        system_label: "default",
        name: "Password Reset Not Registered",
        subject: "Reset password attempt for {{account.name}}",
        to: "{{email}}",
        content_html: password_reset_not_registered_html,
        content_text: password_reset_not_registered_text
      }
    end

    def email_confirmation(account) do
      email_confirmation_html = File.read!("lib/blue_jet/notification/email_templates/email_confirmation.html")
      email_confirmation_text = File.read!("lib/blue_jet/notification/email_templates/email_confirmation.txt")

      %EmailTemplate{
        account_id: account.id,
        system_label: "default",
        name: "Email Confirmation",
        subject: "Confirm your email for {{account.name}}",
        to: "{{user.email}}",
        content_html: email_confirmation_html,
        content_text: email_confirmation_text
      }
    end
  end
end
