defmodule BlueJet.Identity.Account do
  use BlueJet, :data

  alias BlueJet.Identity.RefreshToken
  alias BlueJet.Identity.Account
  alias BlueJet.Identity.AccountMembership

  schema "accounts" do
    field :name, :string

    timestamps()

    has_many :refresh_tokens, RefreshToken
    has_many :memberships, AccountMembership
  end

  @type t :: Ecto.Schema.t

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name])
  end

  defmodule Query do
    use BlueJet, :query

    def default() do
      from(a in Account, order_by: [desc: :inserted_at])
    end
  end
end
