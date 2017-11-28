defmodule BlueJet.DataTrading.DataImport do
  use BlueJet, :data

  alias BlueJet.Repo
  alias Ecto.Changeset

  alias BlueJet.DataTrading.DataImport

  @type t :: Ecto.Schema.t

  schema "data_imports" do
    field :account_id, Ecto.UUID
    field :status, :string, default: "pending"
    field :data_url, :string
    field :data_type, :string
    field :data_count, :integer
    field :time_spent_sceonds, :integer

    timestamps()
  end

  def system_fields do
    [
      :id,
      :status,
      :data_count,
      :time_spent_sceonds,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    DataImport.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    DataImport.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id]
  end

  def required_fields() do
    [:data_url, :data_type]
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields())
    |> foreign_key_constraint(:account_id)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, castable_fields(struct))
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
