defmodule BlueJet.CRM.PointTransaction do
  use BlueJet, :data

  use Trans, translates: [:description, :custom_data], container: :translations

  alias Ecto.Changeset
  alias Ecto.Multi

  alias BlueJet.Translation

  alias BlueJet.CRM.PointTransaction
  alias BlueJet.CRM.PointAccount

  schema "point_transactions" do
    field :account_id, Ecto.UUID

    field :status, :string, default: "pending"
    field :amount, :integer
    field :balance_after_commit, :integer
    field :reason_label, :string
    field :description, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :source_id, Ecto.UUID
    field :source_type, :string

    field :customer_id, :string, virtual: true

    timestamps()

    belongs_to :point_account, PointAccount
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    PointTransaction.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    PointTransaction.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields() ++ [:customer_id]
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    (writable_fields() -- [:account_id]) ++ [:customer_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required([:account_id, :status, :customer_id, :amount])
    |> foreign_key_constraint(:account_id)
  end

  def put_point_account_id(changeset = %{ changes: %{ customer_id: customer_id } }) do
    point_account = Repo.get_by!(PointAccount, customer_id: customer_id)
    put_change(changeset, :point_account_id, point_account.id)
  end
  def put_point_account_id(changeset), do: changeset

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> put_point_account_id()
    |> Translation.put_change(translatable_fields(), locale)
  end

  # TODO: Check there is enough point to commit the transaction
  def commit(point_transaction = %{ status: "pending" }) do
    point_account = Repo.get(PointAccount, point_transaction.point_account_id)
    changeset = change(point_transaction, %{ status: "committed" })

    statements = Multi.new()
    |> Multi.update(:point_transaction, changeset)
    |> Multi.run(:point_account, fn(%{ point_transaction: point_transaction }) ->
        new_balance = point_account.balance + point_transaction.amount
        changeset = Changeset.change(point_account, %{ balance: new_balance })
        Repo.update(changeset)
       end)

    case Repo.transaction(statements) do
      {:ok, %{ point_transaction: point_transaction }} ->
        {:ok, point_transaction}
      {:error, :point_account, changeset, _} ->
        {:error, changeset.errors}
    end
  end

  defmodule Query do
    use BlueJet, :query

    def for_account(query, account_id) do
      from(pt in query, where: pt.account_id == ^account_id)
    end

    def preloads(_) do
      []
    end

    def default() do
      from(pt in PointTransaction, order_by: [desc: :inserted_at])
    end
  end
end
