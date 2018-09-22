defmodule BlueJet.Crm.PointTransaction do
  use BlueJet, :data

  alias BlueJet.Crm.PointAccount
  alias __MODULE__.Proxy

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

  @type t :: Ecto.Schema.t()

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
    [
      :name,
      :caption,
      :description,
      :custom_data
    ]
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  @spec changeset(__MODULE__.t(), atom, map) :: Changeset.t()
  def changeset(point_transaction, :insert, params) do
    point_transaction
    |> cast(params, writable_fields())
    |> put_committed_at()
    |> validate()
  end

  @spec changeset(__MODULE__.t(), atom, map, String.t(), String.t()) :: Changeset.t()
  def changeset(point_transaction, :update, params, locale \\ nil, default_locale \\ nil) do
    point_transaction = Proxy.put_account(point_transaction)
    default_locale = default_locale || point_transaction.account.default_locale
    locale = locale || default_locale

    point_transaction
    |> cast(params, writable_fields())
    |> put_committed_at()
    |> validate()
    |> Translation.put_change(translatable_fields(), locale)
  end

  @spec changeset(__MODULE__.t(), atom) :: Changeset.t()
  def changeset(point_transaction, :delete) do
    change(point_transaction)
    |> Map.put(:action, :delete)
    |> validate()
  end

  defp put_committed_at(
         changeset = %{
           valid?: true,
           data: %{status: "pending"},
           changes: %{status: "committed"}
         }
       ) do
    put_change(changeset, :committed_at, Ecto.DateTime.utc())
  end

  defp put_committed_at(changeset), do: changeset

  @spec validate(Changeset.t()) :: Changeset.t()
  def validate(changeset = %{action: :delete}) do
    if get_field(changeset, :status) == "pending" do
      changeset
    else
      add_error(changeset, :status, {"Only pending transaction can be deleted.", code: :undeletable})
    end
  end

  def validate(changeset) do
    changeset
    |> validate_required([:status, :amount])
    |> validate_number(:balance_after_commit, greater_than_or_equal_to: 0)
  end

  @spec sync_to_point_account(__MODULE__.t()) :: {:ok, __MODULE__.t()}
  def sync_to_point_account(
        %{status: "committed", balance_after_commit: balance} = point_transaction
      ) do
    point_transaction = Repo.preload(point_transaction, :point_account)
    point_account = point_transaction.point_account

    changeset = change(point_account, %{balance: balance})
    {:ok, _} = Repo.update(changeset)

    {:ok, point_transaction}
  end

  def sync_to_point_account(point_transaction), do: {:ok, point_transaction}
end
