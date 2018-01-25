defmodule BlueJet.DataTrading.DataImport do
  use BlueJet, :data

  schema "data_imports" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string, default: "pending"
    field :data_url, :string
    field :data_type, :string
    field :data_count, :integer
    field :time_spent_sceonds, :integer

    timestamps()
  end

  @type t :: Ecto.Schema.t

  @system_fields [
    :id,
    :account_id,
    :status,
    :data_count,
    :time_spent_sceonds,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  def translatable_fields do
    []
  end

  def required_fields() do
    [:data_url, :data_type]
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields())
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, writable_fields())
    |> validate()
  end

  defmodule Query do
    use BlueJet, :query

    def for_account(query, account_id) do
      from(di in query, where: di.account_id == ^account_id)
    end

    def default() do
      from(di in DataImport, order_by: [desc: :updated_at])
    end
  end
end
