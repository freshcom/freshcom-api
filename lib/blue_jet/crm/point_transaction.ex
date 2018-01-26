defmodule BlueJet.Crm.PointTransaction do
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias BlueJet.Crm.PointAccount
  alias BlueJet.Crm.IdentityService

  schema "point_transactions" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string, default: "pending"
    field :code, :string
    field :name, :string
    field :label, :string

    field :reason_label, :string
    field :amount, :integer
    field :balance_after_commit, :integer

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :committed_at, :utc_datetime

    field :source_id, Ecto.UUID
    field :source_type, :string
    field :source, :map, virtual: true

    timestamps()

    belongs_to :point_account, PointAccount
  end

  @system_fields [
    :id,
    :account_id,
    :balance_after_commit,
    :committed_at,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  def translatable_fields do
    __MODULE__.__trans__(:fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required([:status, :amount])
  end

  # def put_point_account_id(changeset = %{ changes: %{ customer_id: customer_id } }) do
  #   point_account = Repo.get_by!(PointAccount, customer_id: customer_id)
  #   put_change(changeset, :point_account_id, point_account.id)
  # end
  # def put_point_account_id(changeset), do: changeset

  defp put_committed_at(changeset = %{
    valid?: true,
    data: %{ status: "pending" },
    changes: %{ status: "committed" }
  }) do
    put_change(changeset, :committed_at, Ecto.DateTime.utc())
  end

  defp put_committed_at(changeset), do: changeset

  defp put_balance_after_commit(changeset = %{
    valid?: true,
    data: %{ status: "pending" },
    changes: %{ status: "committed" }
  }) do
    point_account_id = get_field(changeset, :point_account_id)
    point_account = Repo.get(PointAccount, point_account_id)

    amount = get_field(changeset, :amount)
    new_balance = point_account.balance + amount
    put_change(changeset, :balance_after_commit, new_balance)
  end

  defp put_balance_after_commit(changeset), do: changeset

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(point_transaction, params \\ %{}, locale \\ nil, default_locale \\ nil) do
    point_transaction = %{ point_transaction | account: get_account(point_transaction) }
    default_locale = default_locale || point_transaction.account.default_locale
    locale = locale || default_locale

    point_transaction
    |> cast(params, writable_fields())
    |> validate()
    |> put_committed_at()
    |> put_balance_after_commit()
    |> Translation.put_change(translatable_fields(), locale)
  end

  def process(point_transaction, %{
    data: %{ status: "pending" },
    changes: %{ status: "committed" }
  }) do
    point_transaction = Repo.preload(point_transaction, :point_account)
    point_account = point_transaction.point_account

    changeset = change(point_account, %{ balance: point_transaction.balance_after_commit })
    Repo.update(changeset)
  end

  def process(point_transaction, _), do: {:ok, point_transaction}

  #
  # ExternalFile
  #
  def get_account(point_transaction) do
    point_transaction.account || IdentityService.get_account(point_transaction)
  end

  use BlueJet.FileStorage.Macro,
    put_external_resources: :external_file_collection,
    field: :external_file_collections,
    owner_type: "PointTransaction"

  def put_external_resources(point_transaction, _, _), do: point_transaction

  defmodule Query do
    use BlueJet, :query

    alias BlueJet.Crm.PointTransaction

    def default() do
      from(pt in PointTransaction, order_by: [desc: pt.inserted_at])
    end

    def committed(query) do
      from pt in query, where: pt.status == "committed"
    end

    def limit(query, limit) do
      from pt in query, limit: ^limit
    end

    def for_point_account(query, point_account_id) do
      from(pt in query, where: pt.point_account_id == ^point_account_id)
    end

    def for_account(query, account_id) do
      from(pt in query, where: pt.account_id == ^account_id)
    end

    def preloads({:point_account, point_account_preloads}, options) do
      [point_account: {PointAccount.Query.default(), PointAccount.Query.preloads(point_account_preloads, options)}]
    end

    def preloads(_, _) do
      []
    end
  end
end
