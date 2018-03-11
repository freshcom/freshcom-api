defmodule BlueJet.Crm.PointTransaction do
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias BlueJet.Crm.PointAccount
  alias BlueJet.Crm.PointTransaction.Proxy

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

  def validate(changeset = %{ action: :delete }) do
    if get_field(changeset, :amount) == 0 do
      changeset
    else
      add_error(changeset, :amount, {"must be zero", [validation: :must_be_zero]})
    end
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
  def changeset(point_transaction, :insert, params) do
    point_transaction
    |> cast(params, writable_fields())
    |> validate()
    |> put_committed_at()
    |> put_balance_after_commit()
  end

  def changeset(point_transaction, :update, params, locale \\ nil, default_locale \\ nil) do
    point_transaction = Proxy.put_account(point_transaction)
    default_locale = default_locale || point_transaction.account.default_locale
    locale = locale || default_locale

    point_transaction
    |> cast(params, writable_fields())
    |> validate()
    |> put_committed_at()
    |> put_balance_after_commit()
    |> Translation.put_change(translatable_fields(), locale)
  end

  def changeset(point_transaction, :delete) do
    change(point_transaction)
    |> Map.put(:action, :delete)
    |> validate()
  end

  def process(point_transaction, %{
    data: %{ status: "pending" },
    changes: %{ status: "committed" }
  }) do
    point_transaction = Repo.preload(point_transaction, :point_account)
    point_account = point_transaction.point_account

    changeset = change(point_account, %{ balance: point_transaction.balance_after_commit })
    Repo.update(changeset)

    {:ok, point_transaction}
  end

  def process(point_transaction, _), do: {:ok, point_transaction}
end
