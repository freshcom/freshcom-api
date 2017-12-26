defmodule BlueJet.CRM.PointAccount do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  alias BlueJet.Translation

  alias BlueJet.CRM.PointAccount
  alias BlueJet.CRM.PointTransaction
  alias BlueJet.CRM.Customer

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

  defmodule Query do
    use BlueJet, :query

    def for_account(query, account_id) do
      from(pa in query, where: pa.account_id == ^account_id)
    end

    def preloads({:transactions, transaction_preloads}, options) do
      query =
        PointTransaction.Query.default()
        |> PointTransaction.Query.committed()
        |> PointTransaction.Query.limit(10)

      [transactions: {query, PointTransaction.Query.preloads(transaction_preloads, options)}]
    end
    def preloads(_, _) do
      []
    end

    def default() do
      from(pa in PointAccount, order_by: [desc: pa.updated_at])
    end
  end
end
