defmodule BlueJet.Crm.PointAccount do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  alias BlueJet.Translation

  alias BlueJet.Crm.PointAccount
  alias BlueJet.Crm.PointTransaction
  alias BlueJet.Crm.Customer

  schema "point_accounts" do
    field :account_id, Ecto.UUID

    field :status, :string, default: "active"
    field :balance, :integer, default: 0

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :customer, Customer
    has_many :transactions, PointTransaction
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    PointAccount.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    PointAccount.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required([:account_id, :status, :balance])
    |> foreign_key_constraint(:account_id)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> Translation.put_change(translatable_fields(), locale)
  end
end
