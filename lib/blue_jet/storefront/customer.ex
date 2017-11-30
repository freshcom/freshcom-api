defmodule BlueJet.Storefront.Customer do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  alias BlueJet.Repo
  alias Ecto.Changeset
  alias BlueJet.Translation
  alias BlueJet.Identity.RefreshToken
  alias BlueJet.Storefront.Customer
  alias BlueJet.Storefront.Unlock
  alias BlueJet.Storefront.Order
  alias BlueJet.Storefront.Card
  alias BlueJet.FileStorage.ExternalFileCollection

  @type t :: Ecto.Schema.t

  schema "customers" do
    field :account_id, Ecto.UUID
    field :code, :string
    field :status, :string, default: "guest"
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :label, :string
    field :other_name, :string
    field :phone_number, :string

    field :stripe_customer_id, :string

    field :user_id, Ecto.UUID

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    has_many :unlocks, Unlock
    has_many :orders, Order
    belongs_to :enroller, Customer
    belongs_to :sponsor, Customer
  end

  def system_fields do
    [
      :id,
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

  def required_fields(changeset) do
    status = get_field(changeset, :status)
    first_name = get_field(changeset, :first_name)
    last_name = get_field(changeset, :last_name)
    other_name = get_field(changeset, :other_name)

    required_name_fields = if !first_name && !last_name && !other_name do
      [:first_name, :last_name]
    else
      []
    end

    common = writable_fields() -- [:enroller_id, :sponsor_id, :other_name, :first_name, :last_name, :code, :phone_number, :label]
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

  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> Translation.put_change(translatable_fields(), locale)
  end

  def put_external_resources(customer, {:unlocks, unlock_targets}) do
    unlocks = Unlock.put_external_resources(customer.unlocks, unlock_targets)
    %{ customer | unlocks: unlocks }
  end
  def put_external_resources(customer, _) do
    customer
  end

  def match?(nil, params) do
    false
  end
  def match?(customer, params) do
    params = Map.take(params, ["first_name", "last_name", "other_name", "phone_number"])

    leftover = Enum.reject(params, fn({k, v}) ->
      case k do
        "first_name" ->
          String.downcase(v) == remove_space(downcase(customer.first_name))
        "last_name" ->
          String.downcase(v) == remove_space(downcase(customer.last_name))
        "other_name" ->
          String.downcase(v) == remove_space(downcase(customer.other_name))
        "phone_number" ->
          digit_only(v) == digit_only(customer.phone_number)
        "email" ->
          downcase(v) == downcase(customer.email)
      end
    end)

    case length(leftover) do
      0 -> true
      other -> false
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
    {:ok, stripe_customer} = create_stripe_customer(customer)

    customer
    |> Changeset.change(stripe_customer_id: stripe_customer["id"])
    |> Repo.update!()
  end
  def preprocess(customer, _), do: customer

  @spec get_stripe_card_by_fingerprint(Customer.t, String.t) :: map | nil
  defp get_stripe_card_by_fingerprint(customer = %Customer{ stripe_customer_id: stripe_customer_id }, target_fingerprint) when not is_nil(stripe_customer_id) do
    with {:ok, %{ "data" => cards }} <- list_stripe_card(customer) do
      Enum.find(cards, fn(card) -> card["fingerprint"] == target_fingerprint end)
    else
      other -> other
    end
  end

  @spec create_stripe_customer(Customer.t) :: {:ok, map} | {:error, map}
  defp create_stripe_customer(customer) do
    StripeClient.post("/customers", %{ email: customer.email, metadata: %{ fc_customer_id: customer.id } })
  end

  @spec list_stripe_card(Customer.t) :: {:ok, map} | {:error, map}
  defp list_stripe_card(%Customer{ stripe_customer_id: stripe_customer_id }) when not is_nil(stripe_customer_id) do
    StripeClient.get("/customers/#{stripe_customer_id}/sources?object=card&limit=100")
  end

  defmodule Query do
    use BlueJet, :query

    def for_account(query, account_id) do
      from(c in query, where: c.account_id == ^account_id)
    end

    def with_id_or_code(query, id_or_code) do
      case Ecto.UUID.dump(id_or_code) do
        :error -> from(c in query, where: c.code == ^id_or_code)
        other -> from(c in query, where: (c.id == ^id_or_code) or (c.code == ^id_or_code))
      end
    end

    def preloads(:unlocks) do
      [unlocks: Unlock.Query.default()]
    end
    def preloads({:unlocks, unlock_preloads}) do
      [unlocks: Unlock.Query.default()]
    end
    def preloads(:orders) do
      [orders: Order.Query.default() |> Order.Query.not_cart() |> limit(5)]
    end

    def default() do
      from(c in Customer, order_by: [desc: :updated_at])
    end
  end
end
