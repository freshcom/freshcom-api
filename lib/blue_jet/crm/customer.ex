defmodule BlueJet.CRM.Customer do
  use BlueJet, :data

  use Trans, translates: [
    :caption,
    :description,
    :custom_data
  ], container: :translations

  import BlueJet.Identity.Shortcut

  alias BlueJet.Repo
  alias Ecto.Changeset

  alias BlueJet.Translation
  alias BlueJet.AccessRequest

  alias BlueJet.CRM.Customer
  alias BlueJet.CRM.PointAccount

  @type t :: Ecto.Schema.t

  schema "customers" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string, default: "guest"
    field :code, :string
    field :name, :string
    field :label, :string

    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :phone_number, :string

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :stripe_customer_id, :string
    field :user_id, Ecto.UUID

    timestamps()

    has_one :point_account, PointAccount
    belongs_to :enroller, Customer
    belongs_to :sponsor, Customer
  end

  def system_fields do
    [
      :id,
      :user_id,
      :stripe_customer_id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    Customer.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    Customer.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id]
  end

  def required_name_fields(_, _, name) do
    if name do
      []
    else
      [:first_name, :last_name]
    end
  end

  def required_fields(changeset) do
    status = get_field(changeset, :status)
    first_name = get_field(changeset, :first_name)
    last_name = get_field(changeset, :last_name)
    name = get_field(changeset, :name)

    required_name_fields = required_name_fields(first_name, last_name, name)

    common = [:account_id, :status, :user_id]
    common = common ++ required_name_fields

    case status do
      "guest" -> [:account_id, :status]
      "internal" -> [:account_id, :status]
      "registered" -> common
      "suspended" -> common -- [:user_id]
    end
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields(changeset))
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
    |> foreign_key_constraint(:account_id)
    |> unique_constraint(:email)
  end

  def changeset(struct, params, locale, default_locale) do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> put_name()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  def put_name(changeset = %{ changes: %{ name: _ } }), do: changeset

  def put_name(changeset = %{ valid?: true }) do
    first_name = get_field(changeset, :first_name)
    last_name = get_field(changeset, :first_name)

    if first_name && last_name do
      put_change(changeset, :name, "#{first_name} #{last_name}")
    else
      changeset
    end
  end

  def put_name(changeset), do: changeset

  def match?(nil, _) do
    false
  end

  def match?(customer, params) do
    params = Map.take(params, ["first_name", "last_name", "name", "phone_number"])

    leftover = Enum.reject(params, fn({k, v}) ->
      case k do
        "first_name" ->
          String.downcase(v) == remove_space(downcase(customer.first_name))
        "last_name" ->
          String.downcase(v) == remove_space(downcase(customer.last_name))
        "name" ->
          String.downcase(v) == remove_space(downcase(customer.name))
        "phone_number" ->
          digit_only(v) == digit_only(customer.phone_number)
        "email" ->
          downcase(v) == downcase(customer.email)
      end
    end)

    case length(leftover) do
      0 -> true
      _ -> false
    end
  end
  defp downcase(nil) do
    nil
  end
  defp downcase(value) do
    String.downcase(value)
  end
  defp digit_only(nil) do
    nil
  end
  defp digit_only(value) do
    String.replace(value, ~r/[^0-9]/, "")
  end
  defp remove_space(nil) do
    nil
  end
  defp remove_space(value) do
    String.replace(value, " ", "")
  end

  @doc """
  Preprocess the customer to be ready for its first payment
  """
  @spec preprocess(Customer.t, Keyword.t) :: Customer.t
  def preprocess(customer = %Customer{ stripe_customer_id: stripe_customer_id }, payment_processor: "stripe") when is_nil(stripe_customer_id) do
    customer = %{ customer | account: get_account(customer) }
    {:ok, stripe_customer} = create_stripe_customer(customer)

    customer
    |> Changeset.change(stripe_customer_id: stripe_customer["id"])
    |> Repo.update!()
  end
  def preprocess(customer, _), do: customer

  # @spec get_stripe_card_by_fingerprint(Customer.t, String.t) :: map | nil
  # defp get_stripe_card_by_fingerprint(customer = %Customer{ stripe_customer_id: stripe_customer_id }, target_fingerprint) when not is_nil(stripe_customer_id) do
  #   customer = %{ customer | account: get_account(customer) }
  #   with {:ok, %{ "data" => cards }} <- list_stripe_card(customer) do
  #     Enum.find(cards, fn(card) -> card["fingerprint"] == target_fingerprint end)
  #   else
  #     other -> other
  #   end
  # end

  @spec create_stripe_customer(Customer.t) :: {:ok, map} | {:error, map}
  defp create_stripe_customer(customer) do
    account = get_account(customer)
    StripeClient.post("/customers", %{ email: customer.email, metadata: %{ fc_customer_id: customer.id } }, mode: account.mode)
  end

  # @spec list_stripe_card(Customer.t) :: {:ok, map} | {:error, map}
  # defp list_stripe_card(customer = %Customer{ stripe_customer_id: stripe_customer_id }) when not is_nil(stripe_customer_id) do
  #   account = get_account(customer)
  #   StripeClient.get("/customers/#{stripe_customer_id}/sources?object=card&limit=100", mode: account.mode)
  # end

  defmodule Query do
    use BlueJet, :query

    def default() do
      from(c in Customer, order_by: [desc: :updated_at])
    end

    def for_account(query, account_id) do
      from(c in query, where: c.account_id == ^account_id)
    end

    def with_id_or_code(query, id_or_code) do
      case Ecto.UUID.dump(id_or_code) do
        :error -> from(c in query, where: c.code == ^id_or_code)
        _ -> from(c in query, where: (c.id == ^id_or_code) or (c.code == ^id_or_code))
      end
    end

    def preloads({:point_account, point_account_preloads}, options) do
      [point_account: {PointAccount.Query.default(), PointAccount.Query.preloads(point_account_preloads, options)}]
    end

    def preloads(_) do
      []
    end
  end
end
