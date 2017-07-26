defmodule BlueJet.Customer do
  use BlueJet.Web, :model
  use Trans, translates: [:custom_data], container: :translations

  alias BlueJet.Translation

  schema "customers" do
    field :code, :string
    field :status, :string, default: "anonymous"
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :encrypted_password, :string
    field :label, :string
    field :display_name, :string
    field :phone_number, :string

    field :password, :string, virtual: true

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :account, BlueJet.Account
    has_one :refresh_token, BlueJet.RefreshToken
  end

  def fields do
    (BlueJet.Customer.__schema__(:fields)
    -- [:id, :encrypted_password, :inserted_at, :updated_at])
    ++ [:password]
  end

  def translatable_fields do
    BlueJet.Customer.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    fields() -- [:account_id]
  end

  def required_fields(changeset) do
    status = get_field(changeset, :status)

    case status do
      "anonymous" -> [:account_id, :status]
      "registered" -> fields() -- [:display_name, :code, :phone_number, :label]
    end
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields(changeset))
    |> validate_length(:password, min: 8)
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
    |> foreign_key_constraint(:account_id)
    |> unique_constraint(:email)
  end

  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> put_encrypted_password()
    |> Translation.put_change(translatable_fields(), struct.translations, locale)
  end

  defp put_encrypted_password(changeset = %Ecto.Changeset{ valid?: true, changes: %{ password: password } })  do
    put_change(changeset, :encrypted_password, Comeonin.Bcrypt.hashpwsalt(password))
  end
  defp put_encrypted_password(changeset), do: changeset
end
