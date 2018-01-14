defmodule BlueJet.Identity.Account do
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :company_name,
    :website_url,
    :support_email,
    :tech_email,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias BlueJet.Repo

  alias BlueJet.Identity.AccountMembership
  alias BlueJet.Identity.RefreshToken

  schema "accounts" do
    field :mode, :string
    field :test_account_id, Ecto.UUID, virtual: true

    field :name, :string
    field :company_name, :string
    field :default_locale, :string
    field :website_url, :string
    field :support_email, :string
    field :tech_email, :string

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, defualt: %{}

    timestamps()

    belongs_to :live_account, __MODULE__
    has_one :test_account, __MODULE__, foreign_key: :live_account_id
    has_many :memberships, AccountMembership
    has_many :refresh_tokens, RefreshToken
  end

  @type t :: Ecto.Schema.t
  @system_fields [
    :id,
    :mode,
    :test_account_id,
    :live_account_id,
    :translations,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  def translatable_fields do
    __MODULE__.__trans__(:fields)
  end

  def changeset(account, params, locale \\ nil) do
    locale = locale || account.default_locale

    account
    |> cast(params, writable_fields())
    |> validate_required([:name, :default_locale])
    |> Translation.put_change(translatable_fields(), locale, account.default_locale)
  end

  @doc """
  Return the account with `test_account_id` fields added. If given account does not
  have a test account then the original account is returned.
  """
  def put_test_account_id(account = %{ id: live_account_id, mode: "live" }) do
    test_account = Repo.get_by(__MODULE__, mode: "test", live_account_id: live_account_id)

    case test_account do
      nil -> account

      other -> %{ account | test_account_id: test_account.id }
    end
  end

  def put_test_account_id(account), do: account

  defmodule Query do
    use BlueJet, :query

    alias BlueJet.Identity.Account


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
