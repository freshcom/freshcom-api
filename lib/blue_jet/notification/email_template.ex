defmodule BlueJet.Notification.EmailTemplate do
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :subject,
    :to,
    :reply_to,
    :body_html,
    :body_text,
    :description
  ], container: :translations

  alias BlueJet.Notification.Email
  alias BlueJet.Notification.EmailTemplate.Proxy

  schema "email_templates" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true
    field :system_label, :string

    field :name, :string
    field :subject, :string
    field :to, :string
    field :reply_to, :string
    field :body_html, :string
    field :body_text, :string
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
    |> validate_required([:name, :to, :subject, :body_html])
  end

  def changeset(email_template, :insert, params) do
    email_template
    |> cast(params, writable_fields())
    |> validate()
  end

  def changeset(email_template, :update, params, locale \\ nil, default_locale \\ nil) do
    email_template = Proxy.put_account(email_template)
    default_locale = default_locale || email_template.account.default_locale
    locale = locale || default_locale

    email_template
    |> cast(params, writable_fields())
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  def changeset(email_template, :delete) do
    change(email_template)
    |> Map.put(:action, :delete)
  end

  defp id_last_part(id) do
    String.split(id, "-")
    |> List.last()
    |> String.upcase()
  end

  defp dollar_string(cents) do
    :erlang.float_to_binary(cents / 100, [decimals: 2])
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

  def extract_variables("identity.email_verification_token.create.success", %{ account: account, user: user }) do
    %{
      user: Map.take(user, [:id, :email_verification_token, :first_name, :last_name, :email]),
      account: Map.take(account, [:name]),
      freshcom_verify_email_url: System.get_env("VERIFY_EMAIL_URL")
    }
  end

  def extract_variables("storefront.order.opened.success", %{ account: account, order: order }) do
    line_items = Enum.map(order.root_line_items, fn(line_item) ->
      %{
        name: line_item.name,
        sub_total: dollar_string(line_item.sub_total_cents)
      }
    end)

    order =
      order
      |> Map.put(:tax_total, dollar_string(order.tax_one_cents + order.tax_two_cents + order.tax_three_cents))
      |> Map.put(:grand_total, dollar_string(order.grand_total_cents))

    %{
      account: account,
      order: order,
      order_number: order.code || id_last_part(order.id),
      line_items: line_items
    }
  end

  def render_html(%{ body_html: body_html }, variables) do
    :bbmustache.render(body_html, variables, key_type: :atom)
  end

  def render_text(%{ body_text: nil }, _) do
    nil
  end

  def render_text(%{ body_text: body_text }, variables) do
    :bbmustache.render(body_text, variables, key_type: :atom)
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
        body_html: password_reset_html,
        body_text: password_reset_text
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
        body_html: password_reset_not_registered_html,
        body_text: password_reset_not_registered_text
      }
    end

    def email_verification(account) do
      email_verification_html = File.read!("lib/blue_jet/notification/email_templates/email_verification.html")
      email_verification_text = File.read!("lib/blue_jet/notification/email_templates/email_verification.txt")

      %EmailTemplate{
        account_id: account.id,
        system_label: "default",
        name: "Email Confirmation",
        subject: "Confirm your email for {{account.name}}",
        to: "{{user.email}}",
        body_html: email_verification_html,
        body_text: email_verification_text
      }
    end

    def order_confirmation(account) do
      order_confirmation_html = File.read!("lib/blue_jet/notification/email_templates/order_confirmation.html")
      order_confirmation_text = File.read!("lib/blue_jet/notification/email_templates/order_confirmation.txt")

      %EmailTemplate{
        account_id: account.id,
        system_label: "default",
        name: "Order Confirmation",
        subject: "Your order is confirmed",
        to: "{{order.email}}",
        body_html: order_confirmation_html,
        body_text: order_confirmation_text
      }
    end
  end
end
