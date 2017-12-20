defmodule BlueJet.Identity.Account do
  use BlueJet, :data

  alias BlueJet.Repo

  alias BlueJet.Identity.Account
  alias BlueJet.Identity.AccountMembership
  alias BlueJet.Identity.RefreshToken

  schema "accounts" do
    field :name, :string
    field :default_locale, :string
    field :mode, :string
    field :test_account_id, Ecto.UUID, virtual: true

    timestamps()

    belongs_to :live_account, Account
    has_one :test_account, Account, foreign_key: :live_account_id
    has_many :memberships, AccountMembership
    has_many :refresh_tokens, RefreshToken
  end

  @type t :: Ecto.Schema.t

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :default_locale])
  end

  def put_test_account_id(account = %{ id: live_account_id, mode: "live" }) do
    test_account = Repo.get_by!(Account, mode: "test", live_account_id: live_account_id)
    %{ account | test_account_id: test_account.id }
  end
  def put_test_account_id(account), do: account

  defmodule Query do
    use BlueJet, :query

    def has_member(query, user_id) do
      from a in query,
        join: ac in AccountMembership, on: ac.account_id == a.id,
        where: ac.user_id == ^user_id
    end

    def default() do
      from(a in Account, order_by: [desc: :inserted_at])
    end
  end
end
