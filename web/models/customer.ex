defmodule BlueJet.Customer do
  use BlueJet.Web, :model

  schema "customers" do
    field :status, :string, default: "guest"
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :encrypted_password, :string
    field :display_name, :string

    field :password, :string, virtual: true

    timestamps()

    belongs_to :account, BlueJet.Account
  end

  def fields do
    (BlueJet.Customer.__schema__(:fields)
    -- [:id, :encrypted_password, :inserted_at, :updated_at])
    ++ [:password]
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    fields() -- [:account_id]
  end

  def required_fields("member") do
    fields() -- [:display_name]
  end
  def required_fields("guest") do
    [:account_id, :status]
  end

  def validate(changeset) do
    status = get_field(changeset, :status)
    changeset
    |> validate_required(required_fields(status))
    |> validate_length(:password, min: 8)
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
    |> foreign_key_constraint(:account_id)
    |> unique_constraint(:email)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> put_encrypted_password()
  end

  defp put_encrypted_password(changeset = %Ecto.Changeset{ valid?: true, changes: %{ password: password } })  do
    put_change(changeset, :encrypted_password, Comeonin.Bcrypt.hashpwsalt(password))
  end
  defp put_encrypted_password(changeset), do: changeset
end
