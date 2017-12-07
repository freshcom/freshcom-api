defmodule BlueJet.Identity.Account do
  use BlueJet, :data

  alias BlueJet.Identity.Account
  alias BlueJet.Identity.AccountMembership
  alias BlueJet.Identity.RefreshToken

  schema "accounts" do
    field :name, :string
    field :default_locale, :string

    timestamps()

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
