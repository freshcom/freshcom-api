defmodule BlueJet.Billing.Payment do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  alias BlueJet.Repo
  alias Ecto.Changeset
  alias BlueJet.Translation
  alias BlueJet.Billing.Payment
  alias BlueJet.Billing.Refund
  alias BlueJet.Billing.Card

  @type t :: Ecto.Schema.t

  schema "payments" do
    field :account_id, Ecto.UUID
    field :status, :string # pending, paid, partially_refunded, fully_refunded

    field :gateway, :string # online, in_person,
    field :processor, :string # stripe, paypal
    field :method, :string # visa, mastercard ... , cash

    field :pending_amount_cents, :integer
    field :authorized_amount_cents, :integer
    field :paid_amount_cents, :integer
    field :refunded_amount_cents, :integer, default: 0

    field :billing_address_line_one, :string
    field :billing_address_line_two, :string
    field :billing_address_province, :string
    field :billing_address_city, :string
    field :billing_address_country_code, :string
    field :billing_address_postal_code, :string

    field :stripe_charge_id, :string
    field :stripe_customer_id, :string

    field :owner_id, Ecto.UUID
    field :owner_type, :string

    field :target_id, Ecto.UUID
    field :target_type, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :source, :string, virtual: true
    field :save_source, :boolean, virtual: true

    timestamps()

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
    fields = writable_fields() -- [:account_id]

    fields = if payment.paid_amount_cents do
      fields -- [:authorized_amount_cents]
    else
      fields
    end
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
    # |> put_status()
    |> Translation.put_change(translatable_fields(), locale)
  end

  # defp put_status(changeset = %Changeset{ data: %{ status: "authorized", gateway: "online", paid_amount_cents: nil }, changes: %{ paid_amount_cents: paid_amount_cents } }) do
  #   put_change(changeset, :status, "paid")
  # end
  # defp put_status(changeset), do: changeset

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
  Process the given payment using the corresponding gateway and processor.

  This function may change the payment in the database.

  Returns the processed payment.

  The given `payment` should be a payment that is just created/updated using the `changeset`.
  """
  @spec process(Payment.t, Payment.t) :: {:ok, Payment.t} | {:error. map}
  def process(
    payment = %{ gateway: "online" },
    %{ data: %{ pending_amount_cents: nil }, changes: %{ pending_amount_cents: pending_amount_cents } }
  ) do
    send_paylink(payment)
  end
  def process(
    payment = %{ gateway: "online" },
    %{ data: %{ status: "authorized", paid_amount_cents: nil }, changes: %{ paid_amount_cents: paid_amount_cents } }
  ) do
    with {:ok, payment} <- capture(payment) do
      changeset = Payment.changeset(payment, %{ status: "paid" })
      {:ok, Repo.update!(changeset)}
    else
      other -> other
    end
  end
  def process(
    payment = %{ gateway: "online" },
    %{ data: %{ authorized_amount_cents: nil }, changes: %{ authorized_amount_cents: authorized_amount_cents } }
  ) do
    with {:ok, payment} <- charge(payment) do
      changeset = Payment.changeset(payment, %{ status: "authorized" })
      {:ok, Repo.update!(changeset)}
    else
      other -> other
    end
  end
  def process(
    payment = %{ gateway: "online" },
    %{ data: %{ paid_amount_cents: nil }, changes: %{ paid_amount_cents: paid_amount_cents } }
  ) do
    with {:ok, payment} <- charge(payment) do
      changeset = Payment.changeset(payment, %{ status: "paid" })
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
    stripe_data = %{ source: payment.source, customer_id: payment.stripe_customer_id }
    card_status = if payment.save_source, do: "saved_by_owner", else: "kept_by_system"
    card_fields = %{
      account_id: payment.account_id,
      status: card_status,
      owner_id: payment.owner_id,
      owner_type: payment.owner_type
    }

    with {:ok, source} <- Card.keep_stripe_source(stripe_data, card_fields),
         {:ok, stripe_charge} <- create_stripe_charge(payment, source)
    do
      sync_with_stripe_charge(payment, stripe_charge)
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

  @spec create_stripe_charge(Payment.t, String.t) :: {:ok, map} | {:error, map}
  defp create_stripe_charge(
    payment = %{ paid_amount_cents: paid_amount_cents, stripe_customer_id: stripe_customer_id },
    source
  ) when not is_nil(paid_amount_cents) do
    if stripe_customer_id do
      StripeClient.post("/charges", %{
        customer: stripe_customer_id,
        amount: paid_amount_cents,
        source: source,
        capture: true,
        currency: "USD",
        metadata: %{ fc_payment_id: payment.id, fc_account_id: payment.account_id }
      })
    else
      StripeClient.post("/charges", %{
        amount: paid_amount_cents,
        source: source,
        capture: true,
        currency: "USD",
        metadata: %{ fc_payment_id: payment.id, fc_account_id: payment.account_id }
      })
    end
  end
  defp create_stripe_charge(
    payment = %{ authorized_amount_cents: authorized_amount_cents, stripe_customer_id: stripe_customer_id },
    source
  ) when not is_nil(authorized_amount_cents) do
    if stripe_customer_id do
      StripeClient.post("/charges", %{
        customer: stripe_customer_id,
        amount: authorized_amount_cents,
        source: source,
        capture: false,
        currency: "USD",
        metadata: %{ fc_payment_id: payment.id, fc_account_id: payment.account_id }
      })
    else
      StripeClient.post("/charges", %{
        amount: authorized_amount_cents,
        source: source,
        capture: false,
        currency: "USD",
        metadata: %{ fc_payment_id: payment.id, fc_account_id: payment.account_id }
      })
    end
  end

  # defp create_stripe_charge(payment = %{ paid_amount_cents: paid_amount_cents }, _, source) when not is_nil(paid_amount_cents) do
  #   StripeClient.post("/charges", %{ amount: paid_amount_cents, source: source, capture: true, currency: "USD", metadata: %{ fc_payment_id: payment.id, fc_account_id: payment.account_id } })
  # end
  # defp create_stripe_charge(payment = %{ authorized_amount_cents: authorized_amount_cents }, _, source) when not is_nil(authorized_amount_cents) do
  #   StripeClient.post("/charges", %{ amount: authorized_amount_cents, source: source, capture: false, currency: "USD", metadata: %{ fc_payment_id: payment.id, fc_account_id: payment.account_id } })
  # end

  @spec capture_stripe_charge(Payment.t) :: {:ok, map} | {:error, map}
  defp capture_stripe_charge(payment) do
    StripeClient.post("/charges/#{payment.stripe_charge_id}/capture", %{ amount: payment.paid_amount_cents })
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

    def default() do
      from(p in Payment, order_by: [desc: :updated_at])
    end
  end
end
