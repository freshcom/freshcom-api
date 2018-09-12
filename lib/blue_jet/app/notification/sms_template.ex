defmodule BlueJet.Notification.SmsTemplate do
  use BlueJet, :data

  alias BlueJet.Notification.Sms
  alias __MODULE__.Proxy

  schema "sms_templates" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true
    field :system_label, :string

    field :name, :string
    field :to, :string
    field :body, :string
    field :description, :string

    field :translations, :map, default: %{}

    timestamps()

    has_many :smses, Sms, foreign_key: :template_id
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
      :to,
      :body,
      :description
    ]
  end

  @spec changeset(__MODULE__.t(), atom, map) :: Changeset.t()
  def changeset(sms_template, :insert, params) do
    sms_template
    |> cast(params, writable_fields())
    |> validate()
  end

  @spec changeset(__MODULE__.t(), atom, map, String.t(), String.t()) :: Changeset.t()
  def changeset(sms_template, :update, params, locale \\ nil, default_locale \\ nil) do
    sms_template = Proxy.put_account(sms_template)
    default_locale = default_locale || sms_template.account.default_locale
    locale = locale || default_locale

    sms_template
    |> cast(params, writable_fields())
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  @spec changeset(__MODULE__.t(), atom) :: Changeset.t()
  def changeset(sms_template, :delete) do
    change(sms_template)
    |> Map.put(:action, :delete)
  end

  @spec validate(Changeset.t()) :: Changeset.t()
  def validate(changeset) do
    changeset
    |> validate_required([:name, :to, :body])
  end

  @spec extract_variables(String.t(), map) :: map
  def extract_variables("identity:phone_verification_code.create.success", %{phone_verification_code: pvc}) do
    %{
      phone_number: pvc.phone_number,
      code: pvc.value,
      account: Map.take(pvc.account, [:name])
    }
  end

  def extract_variables("identity:user.tfa_code.create.success", %{user: %{account_id: account_id} = user})
  when not is_nil(account_id) do
    %{
      user: user,
      code: user.tfa_code,
      account: Map.take(user.account, [:name])
    }
  end

  @spec render_body(__MODULE__.t(), map) :: String.t()
  def render_body(%{body: body}, variables) do
    :bbmustache.render(body, variables, key_type: :atom)
  end

  @spec render_to(__MODULE__.t(), map) :: String.t()
  def render_to(%{to: to}, variables) do
    :bbmustache.render(to, variables, key_type: :atom)
  end

  defmodule AccountDefault do
    alias BlueJet.Notification.SmsTemplate

    def phone_verification_code(account) do
      %SmsTemplate{
        account_id: account.id,
        system_label: "default",
        name: "Phone Verification Code",
        to: "{{phone_number}}",
        body: "Your {{account.name}} verification code: {{code}}"
      }
    end

    def tfa_code(account) do
      %SmsTemplate{
        account_id: account.id,
        system_label: "default",
        name: "TFA Code",
        to: "{{user.phone_number}}",
        body: "Your {{account.name}} verification code: {{code}}"
      }
    end
  end
end
