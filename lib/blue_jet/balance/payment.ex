defmodule BlueJet.Balance.Payment do
  use BlueJet, :data

  use Trans, translates: [
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias Decimal, as: D
  alias Ecto.Changeset

  alias BlueJet.Balance.{Card, Refund, Settings}
  alias BlueJet.Balance.{StripeClient, IdentityService}
  alias BlueJet.Balance.Payment.Proxy

  schema "payments" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string
    field :code, :string
    field :label, :string

    field :gateway, :string # online, offline,
    field :processor, :string
    field :method, :string

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

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :stripe_charge_id, :string
    field :stripe_transfer_id, :string
    field :stripe_customer_id, :string

    field :owner_id, Ecto.UUID
    field :owner_type, :string

    field :target_id, Ecto.UUID
    field :target_type, :string

    field :source, :string, virtual: true
    field :save_source, :boolean, virtual: true
    field :capture, :boolean, virtual: true, default: true
    field :capture_amount_cents, :integer, virtual: true

    timestamps()

    has_many :refunds, Refund
  end

  @type t :: Ecto.Schema.t

  @system_fields [
    :id,
    :account_id,
    :refunded_amount_cents,
    :transaction_fee_cents,
    :gross_amount_cents,
    :net_amount_cents,
    :processor_fee_cents,
    :refunded_processor_fee_cents,
    :freshcom_fee_cents,
    :refunded_freshcom_fee_cents,
    :stripe_charge_id,
    :stripe_transfer_id,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    (__MODULE__.__schema__(:fields) -- @system_fields)
    ++ [:source, :save_source, :capture, :capture_amount_cents]
  end

  def translatable_fields do
    __MODULE__.__trans__(:fields)
  end

  defp required_fields(changeset) do
    status = get_field(changeset, :status)
    gateway = get_field(changeset, :gateway)
    common = [:gateway, :amount_cents]

    cond do
      gateway == "online" -> common ++ [:processor]
      status == "pending" -> common
      gateway == "offline" && status == "paid" -> common ++ [:method]
      true -> common
    end
  end

  defp validate_capture_amount_cents(changeset = %{ data: %{ status: "authorized", gateway: "freshcom" }, changes: %{ capture_amount_cents: capture_amount_cents } }) do
    authorized_amount_cents = get_field(changeset, :amount_cents)
    case capture_amount_cents > authorized_amount_cents do
      true -> add_error(changeset, :capture_amount_cents, "Capture amount cannot be greater than authorized amount", [validation: "lte_authorized_amount", full_error_message: true])
      _ -> changeset
    end
  end
  defp validate_capture_amount_cents(changeset), do: changeset

  def validate(changeset = %{ action: :delete }) do
    gateway = get_field(changeset, :gateway)

    if gateway == "freshcom" do
      add_error(changeset, :gateway, "must be custom", [validation: :must_be_custom])
    else
      changeset
    end
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields(changeset))
    |> validate_capture_amount_cents()
  end

  defp put_gross_amount_cents(changeset = %{ changes: %{ amount_cents: amount_cents } }) do
    refunded_amount_cents = get_field(changeset, :refunded_amount_cents)
    put_change(changeset, :gross_amount_cents, amount_cents - refunded_amount_cents)
  end

  defp put_gross_amount_cents(changeset), do: changeset

  defp put_net_amount_cents(changeset = %{ changes: %{ amount_cents: _ } }) do
    gross_amount_cents = get_field(changeset, :gross_amount_cents)
    processor_fee_cents = get_field(changeset, :processor_fee_cents)
    refunded_processor_fee_cents = get_field(changeset, :refunded_processor_fee_cents)
    freshcom_fee_cents = get_field(changeset, :freshcom_fee_cents)
    refunded_freshcom_fee_cents = get_field(changeset, :refunded_freshcom_fee_cents)
    net_amount_cents = gross_amount_cents - processor_fee_cents + refunded_processor_fee_cents - freshcom_fee_cents + refunded_freshcom_fee_cents

    put_change(changeset, :net_amount_cents, net_amount_cents)
  end

  defp put_net_amount_cents(changeset), do: changeset

  def changeset(payment, :insert, params) do
    payment
    |> cast(params, writable_fields())
    |> validate()
    |> put_gross_amount_cents()
    |> put_net_amount_cents()
  end

  def changeset(payment, :update, params, locale \\ nil, default_locale \\ nil) do
    payment = Proxy.put_account(payment)
    default_locale = default_locale || payment.account.default_locale
    locale = locale || default_locale

    payment
    |> cast(params, writable_fields())
    |> validate()
    |> put_gross_amount_cents()
    |> put_net_amount_cents()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  def changeset(payment, :delete) do
    change(payment)
    |> Map.put(:action, :delete)
    |> validate()
  end

  ######
  # External Resources
  #####
  use BlueJet.FileStorage.Macro,
    put_external_resources: :file_collection,
    field: :file_collections,
    owner_type: "Payment"

  def put_external_resources(payment, _, _), do: payment

  #####
  # Business Logic
  #####

  def get_destination_amount_cents(payment, balance_settings) do
    payment.amount_cents - get_processor_fee_cents(payment, balance_settings) - get_freshcom_fee_cents(payment, balance_settings)
  end

  def get_processor_fee_cents(%{ amount_cents: amount_cents, processor: "stripe" }, balance_settings) do
    variable_rate = balance_settings.stripe_variable_fee_percentage |> D.div(D.new(100))
    variable_fee_cents = D.new(amount_cents) |> D.mult(variable_rate) |> D.round() |> D.to_integer
    variable_fee_cents + balance_settings.stripe_fixed_fee_cents
  end

  def get_freshcom_fee_cents(%{ amount_cents: amount_cents }, balance_settings) do
    rate = balance_settings.freshcom_transaction_fee_percentage |> D.div(D.new(100))
    D.new(amount_cents) |> D.mult(rate) |> D.round() |> D.to_integer
  end

  def sync_with_refund(payment, refund) do
    refunded_amount_cents = payment.refunded_amount_cents + refund.amount_cents
    refunded_processor_fee_cents = payment.refunded_processor_fee_cents + refund.processor_fee_cents
    refunded_freshcom_fee_cents = payment.refunded_freshcom_fee_cents + refund.freshcom_fee_cents
    gross_amount_cents = payment.amount_cents - refunded_amount_cents
    net_amount_cents = gross_amount_cents - payment.processor_fee_cents + refunded_processor_fee_cents - payment.freshcom_fee_cents + refunded_freshcom_fee_cents

    payment_status = cond do
      refunded_amount_cents >= payment.amount_cents -> "refunded"
      refunded_amount_cents > 0 -> "partially_refunded"
      true -> payment.status
    end

    payment
    |> change(
        status: payment_status,
        refunded_amount_cents: refunded_amount_cents,
        refunded_processor_fee_cents: refunded_processor_fee_cents,
        refunded_freshcom_fee_cents: refunded_freshcom_fee_cents,
        gross_amount_cents: gross_amount_cents,
        net_amount_cents: net_amount_cents
       )
    |> Repo.update!()
  end

  @doc """
  Send a paylink

  Returns the payment
  """
  def send_paylink(payment) do
    {:ok, payment}
  end

  @doc """
  Process the given payment using the corresponding gateway and processor.

  This function may change the payment in the database.

  Returns the processed payment.

  The given `payment` should be a payment that is just created/updated using the `changeset`.
  """
  @spec process(__MODULE__.t, Changeset.t) :: {:ok, __MODULE__.t} | {:error, map}
  def process(
    payment = %{ gateway: "freshcom", source: nil },
    %{ data: %{ amount_cents: nil }, changes: %{ amount_cents: _ } }
  ) do
    send_paylink(payment)
  end
  def process(
    payment = %{ gateway: "freshcom", capture: false },
    %{ data: %{ amount_cents: nil }, changes: %{ amount_cents: _ } }
  ) do
    with {:ok, payment} <- charge(payment) do
      changeset = change(payment, status: "authorized")
      {:ok, Repo.update!(changeset)}
    else
      other -> other
    end
  end
  def process(
    payment = %{ gateway: "freshcom", capture: true },
    %{ data: %{ amount_cents: nil }, changes: %{ amount_cents: _ } }
  ) do
    with {:ok, payment} <- charge(payment) do
      changeset = change(payment, status: "paid")
      {:ok, Repo.update!(changeset)}
    else
      other -> other
    end
  end
  def process(
    payment = %{ gateway: "freshcom" },
    %{ data: %{ status: "authorized", capture_amount_cents: nil }, changes: %{ capture_amount_cents: _ } }
  ) do
    with {:ok, payment} <- capture(payment) do
      changeset = change(payment, status: "paid")
      {:ok, Repo.update!(changeset)}
    else
      other -> other
    end
  end
  def process(payment, _) do
    {:ok, payment}
  end

  @doc """
  Charge the given payment using its online processor.

  This function may change the payment in database.

  Returns the charged payment.
  """
  @spec charge(__MODULE__.t) :: {:ok, __MODULE__.t} | {:error, map}
  def charge(payment = %__MODULE__{ processor: "stripe" }) do
    balance_settings = Settings.for_account(payment.account_id)

    stripe_data = %{ source: payment.source, customer_id: payment.stripe_customer_id }
    card_status = if payment.save_source, do: "saved_by_owner", else: "kept_by_system"
    card_fields = %{
      status: card_status,
      owner_id: payment.owner_id,
      owner_type: payment.owner_type
    }

    with {:ok, source} <- Card.keep_stripe_source(stripe_data, card_fields, %{ account_id: payment.account_id, account: payment.account }),
         {:ok, stripe_charge} <- create_stripe_charge(payment, source, balance_settings)
    do
      sync_with_stripe_charge(payment, stripe_charge)
    else
      {:error, stripe_errors} -> {:error, format_stripe_errors(stripe_errors)}
    end
  end

  @doc """
  This function capture an authorized payment. This function does not check
  whether the payment is actually authorized, it is up to the caller to make
  sure the payment is a valid authorized payment before passing it to this function.
  """
  @spec capture(__MODULE__.t) :: {:ok, __MODULE__.t} | {:error, map}
  def capture(payment = %__MODULE__{ processor: "stripe" }) do
    with {:ok, _} <- capture_stripe_charge(payment) do
      {:ok, payment}
    else
      {:error, stripe_errors} -> {:error, format_stripe_errors(stripe_errors)}
    end
  end

  @spec sync_with_stripe_charge(__MODULE__.t, map) :: {:ok, Payment.t}
  defp sync_with_stripe_charge(payment, stripe_charge = %{ "captured" => true, "amount" => amount_cents }) do
    processor_fee_cents = stripe_charge["balance_transaction"]["fee"]
    freshcom_fee_cents = stripe_charge["amount"] - stripe_charge["transfer"]["amount"] - processor_fee_cents
    gross_amount_cents = amount_cents - payment.refunded_amount_cents
    net_amount_cents = stripe_charge["transfer"]["amount"]

    payment =
      payment
      |> change(
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
      |> change(stripe_charge_id: stripe_charge_id, status: "authorized", authorized_amount_cents: authorized_amount_cents)
      |> Repo.update!()

    {:ok, payment}
  end

  @spec create_stripe_charge(__MODULE__.t, String.t, Settings.t) :: {:ok, map} | {:error, map}
  defp create_stripe_charge(
    payment = %{ capture: capture, stripe_customer_id: stripe_customer_id },
    source,
    balance_settings
  ) do
    destination_amount_cents = get_destination_amount_cents(payment, balance_settings)

    stripe_request = %{
      amount: payment.amount_cents,
      source: source,
      capture: capture,
      currency: "CAD",
      metadata: %{ fc_payment_id: payment.id, fc_account_id: payment.account_id },
      destination: %{ account: balance_settings.stripe_user_id, amount: destination_amount_cents },
      expand: ["transfer", "balance_transaction"]
    }

    stripe_request = if stripe_customer_id do
      Map.put(stripe_request, :customer, stripe_customer_id)
    else
      stripe_request
    end

    account = Proxy.get_account(payment)
    StripeClient.post("/charges", stripe_request, mode: account.mode)
  end

  @spec capture_stripe_charge(__MODULE__.t) :: {:ok, map} | {:error, map}
  defp capture_stripe_charge(payment) do
    account = Proxy.get_account(payment)
    StripeClient.post("/charges/#{payment.stripe_charge_id}/capture", %{ amount: payment.capture_amount_cents }, mode: account.mode)
  end

  defp format_stripe_errors(stripe_errors = %{}) do
    [source: { stripe_errors["error"]["message"], [code: stripe_errors["error"]["code"], full_error_message: true] }]
  end

  defp format_stripe_errors(stripe_errors), do: stripe_errors
end
