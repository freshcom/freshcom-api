defmodule BlueJet.Billing.Payment do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  alias Decimal, as: D
  alias BlueJet.Repo
  alias Ecto.Changeset
  alias BlueJet.Translation
  alias BlueJet.Billing.Payment
  alias BlueJet.Billing.Refund
  alias BlueJet.Billing.Card
  alias BlueJet.Billing.BillingSettings

  @type t :: Ecto.Schema.t

  schema "payments" do
    field :account_id, Ecto.UUID
    field :status, :string # pending, authorized, paid, partially_refunded, fully_refunded

    field :gateway, :string # online, offline,
    field :processor, :string # stripe, paypal
    field :method, :string # visa, mastercard ... , cash

    field :amount_cents, :integer
    field :refunded_amount_cents, :integer, default: 0
    field :gross_amount_cents, :integer, default: 0

    field :processor_fee_cents, :integer, default: 0
    field :refunded_processor_fee_cents, :integer, default: 0

    field :freshcom_fee_cents, :integer, default: 0
    field :refunded_freshcom_fee_cents, :integer, default: 0

    field :net_amount_cents, :integer, default: 0

    field :billing_address_line_one, :string
    field :billing_address_line_two, :string
    field :billing_address_province, :string
    field :billing_address_city, :string
    field :billing_address_country_code, :string
    field :billing_address_postal_code, :string

    field :stripe_charge_id, :string
    field :stripe_transfer_id, :string
    field :stripe_customer_id, :string

    field :owner_id, Ecto.UUID
    field :owner_type, :string

    field :target_id, Ecto.UUID
    field :target_type, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :source, :string, virtual: true
    field :save_source, :boolean, virtual: true
    field :capture, :boolean, virtual: true, default: true

    timestamps()

    has_many :refunds, Refund
  end

  def system_fields do
    [
      :id,
      :refunded_amount_cents,
      :transaction_fee_cents,
      :gross_amount_cents,
      :net_amount_cents,
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
    fields = writable_fields() -- [:account_id]
  end

  def required_fields(changeset) do
    status = get_field(changeset, :status)
    gateway = get_field(changeset, :gateway)
    common = [:account_id, :gateway]

    cond do
      gateway == "online" -> common ++ [:processor]
      status == "pending" -> common
      gateway == "offline" && status == "paid" -> common ++ [:method]
      true -> common
    end
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields(changeset))
    |> validate_paid_amount_cents()
    |> foreign_key_constraint(:account_id)
  end

  defp validate_paid_amount_cents(changeset = %Changeset{ data: %{ status: "authorized", gateway: "online", paid_amount_cents: nil }, changes: %{ paid_amount_cents: paid_amount_cents } }) do
    authorized_amount_cents = get_field(changeset, :authorized_amount_cents)
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
    |> put_gross_amount_cents()
    # |> put_net_amount_cents()
    |> Translation.put_change(translatable_fields(), locale)
  end

  def put_gross_amount_cents(changeset = %{ changes: %{ amount_cents: amount_cents } }) do
    refunded_amount_cents = get_field(changeset, :refunded_amount_cents)
    put_change(changeset, :gross_amount_cents, amount_cents - refunded_amount_cents)
  end
  def put_gross_amount_cents(changeset), do: changeset

  def put_net_amount_cents(changeset = %{ changes: %{ amount_cents: amount_cents } }) do
    gross_amount_cents = get_field(changeset, :gross_amount_cents)
    processor_fee_cents = get_field(changeset, :processor_fee_cents)
    refunded_processor_fee_cents = get_field(changeset, :refunded_processor_fee_cents)
    refreshcom_fee_cents = get_field(changeset, :refreshcom_fee_cents)
    refunded_refreshcom_fee_cents = get_field(changeset, :refunded_refreshcom_fee_cents)
    net_amount_cents = gross_amount_cents - processor_fee_cents + refunded_processor_fee_cents - refreshcom_fee_cents + refunded_refreshcom_fee_cents

    put_change(changeset, :net_amount_cents, net_amount_cents)
  end
  def put_net_amount_cents(changeset), do: changeset

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

  def destination_amount_cents(payment, billing_settings) do
    payment.amount_cents - processor_fee_cents(payment, billing_settings) - freshcom_fee_cents(payment, billing_settings)
  end

  def processor_fee_cents(%{ amount_cents: amount_cents, processor: "stripe" }, billing_settings) do
    variable_rate = billing_settings.stripe_variable_fee_percentage |> D.div(D.new(100))
    variable_fee_cents = D.new(amount_cents) |> D.mult(variable_rate) |> D.round() |> D.to_integer
    variable_fee_cents + billing_settings.stripe_fixed_fee_cents
  end

  def freshcom_fee_cents(%{ amount_cents: amount_cents }, billing_settings) do
    rate = billing_settings.freshcom_transaction_fee_percentage |> D.div(D.new(100))
    D.new(amount_cents) |> D.mult(rate) |> D.round() |> D.to_integer
  end

  def net_amount_cents(payment) do
    payment.amount_cents - payment.refunded_amount_cents
  end

  @doc """
  Send a paylink

  Returns the payment
  """
  def send_paylink(payment) do
    payment
  end

  @doc """
  Process the given payment using the corresponding gateway and processor.

  This function may change the payment in the database.

  Returns the processed payment.

  The given `payment` should be a payment that is just created/updated using the `changeset`.
  """
  @spec process(Payment.t, Changeset.t) :: {:ok, Payment.t} | {:error. map}
  def process(
    payment = %{ gateway: "online", source: nil },
    %{ data: %{ amount_cents: nil }, changes: %{ amount_cents: amount_cents } }
  ) do
    send_paylink(payment)
  end
  def process(
    payment = %{ gateway: "online", capture: false },
    %{ data: %{ amount_cents: nil }, changes: %{ amount_cents: amount_cents } }
  ) do
    with {:ok, payment} <- charge(payment) do
      changeset = Changeset.change(payment, status: "authorized")
      {:ok, Repo.update!(changeset)}
    else
      other -> other
    end
  end
  def process(
    payment = %{ gateway: "online", capture: true },
    %{ data: %{ amount_cents: nil }, changes: %{ amount_cents: amount_cents } }
  ) do
    with {:ok, payment} <- charge(payment) do
      changeset = Changeset.change(payment, status: "paid")
      {:ok, Repo.update!(changeset)}
    else
      other -> other
    end
  end
  def process(
    payment = %{ gateway: "online" },
    %{ data: %{ status: "authorized", capture_amount: nil }, changes: %{ capture_amount: capture_amount } }
  ) do
    with {:ok, payment} <- capture(payment) do
      changeset = Changeset.change(payment, status: "paid")
      {:ok, Repo.update!(changeset)}
    else
      other -> other
    end
  end
  def process(payment, _) do
    {:ok, payment}
  end

  @doc """
  This function capture an authorized payment. This function does not check
  whether the payment is actually authorized, it is up to the caller to make
  sure the payment is a valid authorized payment before passing it to this function.
  """
  @spec capture(Payment.t) :: {:ok, Payment.t} | {:error, map}
  def capture(payment = %Payment{ processor: "stripe" }) do
    with {:ok, stripe_charge} <- capture_stripe_charge(payment) do
      {:ok, payment}
    else
      {:error, stripe_errors} -> {:error, format_stripe_errors(stripe_errors)}
    end
  end

  @doc """
  Charge the given payment using its online processor.

  This function may change the payment in database.

  Returns the charged payment.
  """
  @spec charge(Payment.t) :: {:ok, Payment.t} | {:error, map}
  def charge(payment = %Payment{ processor: "stripe" }) do
    billing_settings = Repo.get_by!(BillingSettings, account_id: payment.account_id)
    stripe_data = %{ source: payment.source, customer_id: payment.stripe_customer_id }
    card_status = if payment.save_source, do: "saved_by_owner", else: "kept_by_system"
    card_fields = %{
      account_id: payment.account_id,
      status: card_status,
      owner_id: payment.owner_id,
      owner_type: payment.owner_type
    }

    with {:ok, source} <- Card.keep_stripe_source(stripe_data, card_fields),
         {:ok, stripe_charge} <- create_stripe_charge(payment, source, billing_settings)
    do
      sync_with_stripe_charge(payment, stripe_charge)
    else
      {:error, stripe_errors} -> {:error, format_stripe_errors(stripe_errors)}
    end
  end

  @spec sync_with_stripe_charge(Payment.t, map) :: {:ok, Payment.t}
  defp sync_with_stripe_charge(payment, stripe_charge = %{ "captured" => true, "amount" => amount_cents }) do
    processor_fee_cents = stripe_charge["balance_transaction"]["fee"]
    freshcom_fee_cents = stripe_charge["amount"] - stripe_charge["transfer"]["amount"] - processor_fee_cents
    gross_amount_cents = amount_cents - payment.refunded_amount_cents
    net_amount_cents = stripe_charge["transfer"]["amount"]

    payment =
      payment
      |> Changeset.change(
          stripe_charge_id: stripe_charge["id"],
          stripe_transfer_id: stripe_charge["transfer"]["id"],
          status: "paid",
          amount_cents: amount_cents,
          gross_amount_cents: gross_amount_cents,
          processor_fee_cents: processor_fee_cents,
          freshcom_fee_cents: freshcom_fee_cents,
          net_amount_cents: net_amount_cents
         )
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

  @spec create_stripe_charge(Payment.t, String.t, BillingSettings.t) :: {:ok, map} | {:error, map}
  defp create_stripe_charge(
    payment = %{ capture: capture, stripe_customer_id: stripe_customer_id },
    source,
    billing_settings
  ) do
    destination_amount_cents = destination_amount_cents(payment, billing_settings)

    stripe_request = %{
      amount: payment.amount_cents,
      source: source,
      capture: capture,
      currency: "CAD",
      metadata: %{ fc_payment_id: payment.id, fc_account_id: payment.account_id },
      destination: %{ account: billing_settings.stripe_user_id, amount: destination_amount_cents },
      expand: ["transfer", "balance_transaction"]
    }

    stripe_request = if stripe_customer_id do
      Map.put(stripe_request, :customer, stripe_customer_id)
    else
      stripe_request
    end

    StripeClient.post("/charges", stripe_request)
  end

  # defp create_stripe_charge(payment = %{ paid_amount_cents: paid_amount_cents }, _, source) when not is_nil(paid_amount_cents) do
  #   StripeClient.post("/charges", %{ amount: paid_amount_cents, source: source, capture: true, currency: "USD", metadata: %{ fc_payment_id: payment.id, fc_account_id: payment.account_id } })
  # end
  # defp create_stripe_charge(payment = %{ authorized_amount_cents: authorized_amount_cents }, _, source) when not is_nil(authorized_amount_cents) do
  #   StripeClient.post("/charges", %{ amount: authorized_amount_cents, source: source, capture: false, currency: "USD", metadata: %{ fc_payment_id: payment.id, fc_account_id: payment.account_id } })
  # end

  @spec capture_stripe_charge(Payment.t) :: {:ok, map} | {:error, map}
  defp capture_stripe_charge(payment) do
    StripeClient.post("/charges/#{payment.stripe_charge_id}/capture", %{ amount: payment.capture_amount })
  end

  defp format_stripe_errors(stripe_errors = %{}) do
    [source: { stripe_errors["error"]["message"], [code: stripe_errors["error"]["code"], full_error_message: true] }]
  end
  defp format_stripe_errors(stripe_errors), do: stripe_errors


  defmodule Query do
    use BlueJet, :query

    def for_account(query, account_id) do
      from(p in query, where: p.account_id == ^account_id)
    end

    def for_target(query, target_type, target_id) do
      from(p in query, where: p.target_type == ^target_type, where: p.target_id == ^target_id)
    end

    def preloads(:refunds) do
      [refunds: Refund.Query.default()]
    end

    def default() do
      from(p in Payment, order_by: [desc: :updated_at])
    end
  end
end
