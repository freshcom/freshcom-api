defmodule BlueJet.Crm.PointAccount do
  use BlueJet, :data

  alias BlueJet.Crm.{PointTransaction, Customer}

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
    __MODULE__.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    [:custom_data]
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

  defp castable_fields(%{__meta__: %{state: :built}}) do
    writable_fields()
  end

  defp castable_fields(%{__meta__: %{state: :loaded}}) do
    writable_fields() -- [:account_id]
  end

  @spec validate(Changeset.t()) :: Changeset.t()
  def validate(changeset) do
    changeset
    |> validate_required([:account_id, :status, :balance])
    |> foreign_key_constraint(:account_id)
  end
end
