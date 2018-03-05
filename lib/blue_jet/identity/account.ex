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

  alias BlueJet.Identity.{AccountMembership, RefreshToken}

  schema "accounts" do
    field :mode, :string
    field :test_account_id, Ecto.UUID, virtual: true

    field :name, :string
    field :company_name, :string
    field :default_locale, :string, default: "en"
    # simple, tfa_sms
    field :default_auth_method, :string, default: "simple"
    field :website_url, :string
    field :support_email, :string
    field :tech_email, :string

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

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

  defp castable_fields(:insert), do: writable_fields()
  defp castable_fields(:update), do: writable_fields() -- [:default_locale]

  def changeset(account, :insert, params) do
    account
    |> cast(params, castable_fields(:insert))
    |> Map.put(:action, :insert)
    |> validate_required([:name, :default_locale])
  end

  def changeset(account, :update, params, locale \\ nil) do
    changeset =
      account
      |> cast(params, castable_fields(:update))
      |> Map.put(:action, :update)
      |> validate_required(:name)

    locale = locale || get_field(changeset, :default_locale)
    default_locale = get_field(changeset, :default_locale)

    Translation.put_change(changeset, translatable_fields(), locale, default_locale)
  end

  def process(account, changeset = %{ action: :update }) do
    account = Repo.preload(account, :test_account)

    test_account =
      change(account.test_account, changeset.changes)
      |> Repo.update!()

    account = %{ account | test_account: test_account }

    {:ok, account}
  end

  @doc """
  Return the account with `test_account_id` fields added. If given account does not
  have a test account then the original account is returned.
  """
  def put_test_account_id(account = %{ id: live_account_id, mode: "live" }) do
    test_account = Repo.get_by(__MODULE__, mode: "test", live_account_id: live_account_id)

    case test_account do
      nil -> account

      _ -> %{ account | test_account_id: test_account.id }
    end
  end

  def put_test_account_id(account), do: account
end
