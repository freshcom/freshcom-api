defmodule BlueJet.Identity.Account do
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias BlueJet.Repo

  alias BlueJet.Identity.Account
  alias BlueJet.Identity.AccountMembership
  alias BlueJet.Identity.RefreshToken

  schema "accounts" do
    field :name, :string
    field :default_locale, :string
    field :mode, :string
    field :test_account_id, Ecto.UUID, virtual: true

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, defualt: %{}

    timestamps()

    belongs_to :live_account, Account
    has_one :test_account, Account, foreign_key: :live_account_id
    has_many :memberships, AccountMembership
    has_many :refresh_tokens, RefreshToken
  end

  @type t :: Ecto.Schema.t

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    Account.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    Account.__trans__(:fields)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(account, params, locale) do
    account
    |> cast(params, writable_fields())
    |> validate_required([:default_locale])
    |> Translation.put_change(translatable_fields(), locale, account.default_locale)
  end

  def put_test_account_id(account = %{ id: live_account_id, mode: "live" }) do
    test_account = Repo.get_by(Account, mode: "test", live_account_id: live_account_id)

    case test_account do
      nil -> account

      other -> %{ account | test_account_id: test_account.id }
    end
  end
  def put_test_account_id(account), do: account

  defmodule Query do
    use BlueJet, :query

    def default() do
      from(a in Account, order_by: [desc: :inserted_at])
    end

    def has_member(query, user_id) do
      from a in query,
        join: ac in AccountMembership, on: ac.account_id == a.id,
        where: ac.user_id == ^user_id
    end

    def live(query) do
      from a in query, where: a.mode == "live"
    end
  end
end
