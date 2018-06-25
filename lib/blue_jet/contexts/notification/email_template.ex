defmodule BlueJet.Notification.EmailTemplate do
  use BlueJet, :data

  alias BlueJet.Notification.Email
  alias __MODULE__.Proxy

  schema "email_templates" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true
    field :system_label, :string

    field :name, :string
    field :subject, :string
    field :from, :string
    field :to, :string
    field :reply_to, :string
    field :body_html, :string
    field :body_text, :string
    field :description, :string

    field :translations, :map, default: %{}

    timestamps()

    has_many :email, Email, foreign_key: :template_id
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
    [
      :name,
      :subject,
      :to,
      :reply_to,
      :body_html,
      :body_text,
      :description
    ]
  end

  @spec changeset(__MODULE__.t(), atom, map) :: Changeset.t()
  def changeset(email_template, :insert, params) do
    email_template
    |> cast(params, writable_fields())
    |> validate()
  end

  @spec changeset(__MODULE__.t(), atom, map, String.t(), String.t()) :: Changeset.t()
  def changeset(email_template, :update, params, locale \\ nil, default_locale \\ nil) do
    email_template = Proxy.put_account(email_template)
    default_locale = default_locale || email_template.account.default_locale
    locale = locale || default_locale

    email_template
    |> cast(params, writable_fields())
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  @spec changeset(__MODULE__.t(), atom) :: Changeset.t()
  def changeset(email_template, :delete) do
    change(email_template)
    |> Map.put(:action, :delete)
  end

  @spec validate(Changeset.t()) :: Changeset.t()
  def validate(changeset) do
    changeset
    |> validate_required([:name, :to, :subject, :body_html])
  end

  @spec extract_variables(String.t(), map) :: map
  def extract_variables("identity.password_reset_token.create.error.username_not_found", %{
        account: account,
        username: username
      }) do
    %{
      username: username,
      account: Map.take(account, [:name]),
      freshcom_reset_password_url: System.get_env("RESET_PASSWORD_URL")
    }
  end

  def extract_variables("identity.password_reset_token.create.success", %{
        account: account,
        user: user
      }) do
    %{
      user: Map.take(user, [:id, :password_reset_token, :first_name, :last_name, :name, :email]),
      account: Map.take(account, [:name]),
      freshcom_reset_password_url: System.get_env("RESET_PASSWORD_URL")
    }
  end

  def extract_variables("identity.email_verification_token.create.success", %{
        account: account,
        user: user
      }) do
    %{
      user: Map.take(user, [:id, :email_verification_token, :first_name, :last_name, :email]),
      account: Map.take(account, [:name]),
      freshcom_verify_email_url: System.get_env("VERIFY_EMAIL_URL")
    }
  end

  def extract_variables("storefront.order.opened.success", %{account: account, order: order}) do
    line_items =
      Enum.map(order.root_line_items, fn line_item ->
        %{
          name: line_item.name,
          order_quantity: line_item.order_quantity,
          sub_total: dollar_string(line_item.sub_total_cents)
        }
      end)

    {:ok, opened_date} = Timex.format(order.opened_at, "%Y-%m-%d", :strftime)

    order =
      order
      |> Map.put(
        :tax_total,
        dollar_string(order.tax_one_cents + order.tax_two_cents + order.tax_three_cents)
      )
      |> Map.put(:grand_total, dollar_string(order.grand_total_cents))
      |> Map.put(:opened_date, opened_date)

    %{
      account: account,
      order: order,
      order_number: order.code || id_last_part(order.id),
      line_items: line_items
    }
  end

  defp id_last_part(id) do
    String.split(id, "-")
    |> List.last()
    |> String.upcase()
  end

  defp dollar_string(cents) do
    :erlang.float_to_binary(cents / 100, decimals: 2)
  end

  @spec render_html(__MODULE__.t(), map) :: String.t()
  def render_html(%{body_html: body_html}, variables) do
    :bbmustache.render(body_html, variables, key_type: :atom)
  end

  @spec render_text(__MODULE__.t(), map) :: String.t()
  def render_text(%{body_text: nil}, _) do
    nil
  end

  def render_text(%{body_text: body_text}, variables) do
    :bbmustache.render(body_text, variables, key_type: :atom)
  end

  @spec render_subject(__MODULE__.t(), map) :: String.t()
  def render_subject(%{subject: subject}, variables) do
    :bbmustache.render(subject, variables, key_type: :atom)
  end

  @spec render_to(__MODULE__.t(), map) :: String.t()
  def render_to(%{to: to}, variables) do
    :bbmustache.render(to, variables, key_type: :atom)
  end

  defmodule AccountDefault do
    alias BlueJet.Notification.EmailTemplate

    def password_reset(account) do
      password_reset_html =
        File.read!("lib/blue_jet/contexts/notification/email_templates/password_reset.html")

      password_reset_text =
        File.read!("lib/blue_jet/contexts/notification/email_templates/password_reset.txt")

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
      password_reset_not_registered_html =
        File.read!(
          "lib/blue_jet/contexts/notification/email_templates/password_reset_not_registered.html"
        )

      password_reset_not_registered_text =
        File.read!(
          "lib/blue_jet/contexts/notification/email_templates/password_reset_not_registered.txt"
        )

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
      email_verification_html =
        File.read!("lib/blue_jet/contexts/notification/email_templates/email_verification.html")

      email_verification_text =
        File.read!("lib/blue_jet/contexts/notification/email_templates/email_verification.txt")

      %EmailTemplate{
        account_id: account.id,
        system_label: "default",
        name: "Email Verification",
        subject: "Verify your email for {{account.name}}",
        to: "{{user.email}}",
        body_html: email_verification_html,
        body_text: email_verification_text
      }
    end

    def order_confirmation(account) do
      order_confirmation_html =
        File.read!("lib/blue_jet/contexts/notification/email_templates/order_confirmation.html")

      order_confirmation_text =
        File.read!("lib/blue_jet/contexts/notification/email_templates/order_confirmation.txt")

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
