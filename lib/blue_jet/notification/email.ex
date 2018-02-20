defmodule BlueJet.Notification.Email do
  use BlueJet, :data

  alias BlueJet.Identity.User
  alias BlueJet.Notification.Trigger

  schema "emails" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string, default: "pending"

    field :subject, :string
    field :to, :string
    field :from, :string
    field :reply_to, :string
    field :content_html, :string
    field :content_text, :string
    field :locale, :string

    timestamps()

    belongs_to :recipient, User
    belongs_to :trigger, Trigger
    belongs_to :template, EmailTemplate
  end

  @type t :: Ecto.Schema.t

  @system_fields [
    :id,
    :account_id,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  defmodule Factory do
    alias Bamboo.Email, as: E
    alias Bamboo.PostmarkHelper, as: Postmark

    def password_reset_not_registered_email(email) do
      E.new_email()
      |> Postmark.template("4758663", %{
          brand_name: "Freshcom",
          brand_url: System.get_env("MARKETING_WEBSITE_URL"),
          email: email,
          signup_url: System.get_env("SIGNUP_URL"),
          forgot_password_url: System.get_env("FORGOT_PASSWORD_URL"),
          support_url: System.get_env("SUPPORT_WEBSITE_URL"),
          company_name: System.get_env("COMPANY_NAME"),
          company_address: System.get_env("COMPANY_ADDRESS")
         })
      |> E.to("roy@freshcom.io")
      |> E.from(sender())
    end

    def password_reset_email(user) do
      E.new_email()
      |> Postmark.template("4561302", %{
          brand_name: "Freshcom",
          brand_url: System.get_env("MARKETING_WEBSITE_URL"),
          name: user.first_name || user.name,
          action_url: password_reset_url(user.password_reset_token),
          support_url: System.get_env("SUPPORT_WEBSITE_URL"),
          company_name: System.get_env("COMPANY_NAME"),
          company_address: System.get_env("COMPANY_ADDRESS")
         })
      |> E.to("roy@freshcom.io")
      |> E.from(sender())
    end

    defp password_reset_url(password_reset_token) do
      base_url = System.get_env("RESET_PASSWORD_URL")
      "#{base_url}?token=#{password_reset_token}"
    end

    defp sender do
      {System.get_env("GLOBAL_MAIL_SENDER_NAME"), System.get_env("GLOBAL_MAIL_SENDER")}
    end
  end
end
