defmodule BlueJet.Storefront.Payment do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  alias BlueJet.Repo
  alias Ecto.Changeset
  alias BlueJet.Translation
  alias BlueJet.Storefront.Payment
  alias BlueJet.Storefront.Refund
  alias BlueJet.Storefront.Order
  alias BlueJet.Identity.Account

  @type t :: Ecto.Schema.t

  schema "payments" do
    field :status, :string # pending, paid, partially_refunded, fully_refunded

    field :gateway, :string # online, in_person,
    field :processor, :string # stripe, paypal
    field :method, :string # visa, mastercard ... , cash

    field :pending_amount_cents, :integer
    field :authorized_amount_cents, :integer
    field :paid_amount_cents, :integer
    field :refunded_amount_cents, :integer

    field :billing_address_line_one, :string
    field :billing_address_line_two, :string
    field :billing_address_province, :string
    field :billing_address_city, :string
    field :billing_address_country_code, :string
    field :billing_address_postal_code, :string

    field :stripe_charge_id, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :source, :string, virtual: true
    field :save_source, :boolean, virtual: true

    timestamps()

    belongs_to :account, Account
    belongs_to :order, Order
    belongs_to :customer, Customer
    has_many :refunds, Refund
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    (Payment.__schema__(:fields) -- system_fields())
    ++ [:source, :save_source]
  end

  def translatable_fields do
    Payment.__trans__(:fields)
  end

  def castable_fields(%Payment{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(payment = %Payment{ __meta__: %{ state: :loaded }}) do
    fields = writable_fields() -- [:account_id, :order_id]

    fields = if payment.paid_amount_cents do
      fields -- [:authorized_amount_cents]
    else
      fields
    end
  end

  def required_fields(changeset) do
    status = get_field(changeset, :status)
    gateway = get_field(changeset, :gateway)
    common = [:account_id, :order_id, :gateway]

    cond do
      status == "pending" -> common
      status == "paid" && gateway == "online" -> common ++ [:processor]
      status == "paid" && gateway == "offline" -> common ++ [:method]
      true -> common
    end
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields(changeset))
    |> validate_paid_amount_cents()
    |> validate_assoc_account_scope(:order)
  end

  defp validate_paid_amount_cents(changeset = %Changeset{ data: %{ status: "authorized", gateway: "online", paid_amount_cents: nil, authorized_amount_cents: authorized_amount_cents }, changes: %{ paid_amount_cents: paid_amount_cents } }) do
    case paid_amount_cents > authorized_amount_cents do
      true -> Changeset.add_error(changeset, :paid_amount_cents, "Paid Amount Cents cannot be greater than Authorized Amount Cents", [validation: "paid_amount_cents_must_be_smaller_or_equal_to_authorized_amount_cents", full_error_message: true])
      _ -> changeset
    end
  end
  defp validate_paid_amount_cents(changeset), do: changeset

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> put_status()
    |> Translation.put_change(translatable_fields(), locale)
  end

  defp put_status(changeset = %Changeset{ data: %{ status: "authorized", gateway: "online", paid_amount_cents: nil }, changes: %{ paid_amount_cents: paid_amount_cents } }) do
    put_change(changeset, :status, "paid")
  end
  defp put_status(changeset), do: changeset

  def query() do
    from(p in Payment, order_by: [desc: p.updated_at, desc: p.inserted_at])
  end

  def preload(struct_or_structs, targets) when length(targets) == 0 do
    struct_or_structs
  end
  def preload(struct_or_structs, targets) when is_list(targets) do
    [target | rest] = targets

    struct_or_structs
    |> Repo.preload(preload_keyword(target))
    |> Payment.preload(rest)
  end

  def preload_keyword(:refunds) do
    [refunds: Refund.query()]
  end


  #####
  # Business Logic
  #####

  alias BlueJet.Identity.Customer

  @doc """
  Send a paylink

  Returns the payment
  """
  def send_paylink(payment) do
    payment
  end

  @doc """
  Process the given payment.

  This function may change the payment in the database.

  Returns the processed payment.

  The given `payment` should be a payment that is just created/updated using the `changeset`.
  """
  @spec process(Payment.t, Changeset.t) :: {:ok, Payment.t} | {:error. map}
  def process(payment, changest = %Changeset{ data: %Payment{ gateway: nil }, changes: %{ gateway: "offline" } }) do
    payment = Repo.preload(payment, :order)
    pending_amount_cents = if payment.order.is_estimate do
      payment.order.authorization_cents
    else
      payment.order.grand_total_cents
    end

    changeset = Changeset.change(payment, pending_amount_cents: pending_amount_cents)
    payment = Repo.update!(changeset)

    {:ok, payment}
  end
  def process(payment, changeset = %Changeset{ data: %Payment{ gateway: nil, status: nil }, changes: %{ gateway: "online", status: "pending" } }) do
    send_paylink(payment)
  end
  def process(payment, changeset = %Changeset{ data: %Payment{ gateway: nil, status: nil }, changes: %{ gateway: "online", status: "paid" } }) do
    charge(payment)
  end
  def process(payment, changeset = %Changeset{ data: %Payment{ gateway: "online", paid_amount_cents: nil }, changes: %{ paid_amount_cents: paid_amount_cents } }) do
    capture(payment)
  end

  @doc """
  Charge the given payment using its online processor.

  This function may change the payment in the database.

  Returns the charged payment.
  """
  @spec charge(Payment.t) :: {:ok, Payment.t} | {:error, map}
  def charge(payment = %Payment{ status: "paid", processor: "stripe", source: source, save_source: save_source }) do
    payment = payment |> Repo.preload(order: :customer)
    customer = payment.order.customer
    order = payment.order
    keep_source_status = if save_source, do: "saved_by_customer", else: "kept_by_system"

    with {:ok, source} <- Customer.keep_stripe_source(customer, source, status: keep_source_status),
         {:ok, stripe_charge} <- create_stripe_charge(payment, order, customer, source)
    do
      sync_with_stripe_charge(payment, stripe_charge)
    else
      {:error, stripe_errors} -> {:error, format_stripe_errors(stripe_errors)}
    end
  end

  @spec capture(Payment.t) :: {:ok, Payment.t} | {:error, map}
  def capture(payment = %Payment{ status: "paid", processor: "stripe" }) do
    with {:ok, stripe_charge} <- capture_stripe_charge(payment) do
      {:ok, payment}
    else
      {:error, stripe_errors} -> {:error, format_stripe_errors(stripe_errors)}
    end
  end

  @spec sync_with_stripe_charge(Payment.t, map) :: {:ok, Payment.t}
  defp sync_with_stripe_charge(payment, %{ "captured" => true, "id" => stripe_charge_id, "amount" => paid_amount_cents }) do
    payment =
      payment
      |> Changeset.change(stripe_charge_id: stripe_charge_id, status: "paid", paid_amount_cents: paid_amount_cents)
      |> Repo.update!()

    {:ok, payment}
  end
  defp sync_with_stripe_charge(payment, %{ "captured" => false, "id" => stripe_charge_id, "amount" => authorized_amount_cents }) do
    payment =
      payment
      |> Changeset.change(stripe_charge_id: stripe_charge_id, status: "authorized", authorized_amount_cents: authorized_amount_cents)
      |> Repo.update!()

    {:ok, payment}
  end

  # TODO: create the stripe customer if it is not already created before this step
  @spec create_stripe_charge(Payment.t, Order.t, Customer.t, String.t) :: {:ok, map} | {:error, map}
  defp create_stripe_charge(payment, %Order{ is_estimate: true, authorization_cents: authorization_cents }, %Customer{ stripe_customer_id: stripe_customer_id }, source) do
    StripeClient.post("/charges", %{ amount: authorization_cents, customer: stripe_customer_id, source: source, capture: false, currency: "USD", metadata: %{ fc_payment_id: payment.id, fc_account_id: payment.account_id } })
  end
  defp create_stripe_charge(payment, %Order{ is_estimate: true, authorization_cents: authorization_cents }, _, source) do
    StripeClient.post("/charges", %{ amount: authorization_cents, source: source, capture: false, currency: "USD", metadata: %{ fc_payment_id: payment.id, fc_account_id: payment.account_id }  })
  end
  defp create_stripe_charge(payment, %Order{ is_estimate: false, grand_total_cents: grand_total_cents }, %Customer{ stripe_customer_id: stripe_customer_id }, source) do
    StripeClient.post("/charges", %{ amount: grand_total_cents, customer: stripe_customer_id, source: source, currency: "USD", metadata: %{ fc_payment_id: payment.id, fc_account_id: payment.account_id }  })
  end
  defp create_stripe_charge(payment, %Order{ is_estimate: false, grand_total_cents: grand_total_cents }, _, source) do
    StripeClient.post("/charges", %{ amount: grand_total_cents, source: source, currency: "USD", metadata: %{ fc_payment_id: payment.id, fc_account_id: payment.account_id }  })
  end

  @spec capture_stripe_charge(Payment.t) :: {:ok, map} | {:error, map}
  defp capture_stripe_charge(payment) do
    StripeClient.post("/charges/#{payment.stripe_charge_id}/capture", %{ amount: payment.paid_amount_cents })
  end

  defp format_stripe_errors(stripe_errors) do
    [source: { stripe_errors["error"]["message"], [code: stripe_errors["error"]["code"], full_error_message: true] }]
  end
end
