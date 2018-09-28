defmodule BlueJet.Balance.Payment do
  use BlueJet, :data

  alias Decimal, as: D
  alias Ecto.Changeset

  alias BlueJet.Balance.{Card, Refund, Settings}
  alias BlueJet.Balance.Payment.Proxy

  schema "payments" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string
    field :code, :string
    field :label, :string

    # freshcom, custom
    field :gateway, :string
    field :processor, :string
    field :method, :string

    field :amount_cents, :integer
    field :refunded_amount_cents, :integer, default: 0
    field :gross_amount_cents, :integer, default: 0
    field :destination_amount_cents, :integer, virtual: true

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

  @type t :: Ecto.Schema.t()

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
    (__MODULE__.__schema__(:fields) -- @system_fields) ++
      [:source, :save_source, :capture, :capture_amount_cents]
  end

  def translatable_fields do
    [:caption, :description, :custom_data]
  end

  @spec changeset(__MODULE__.t(), atom, map) :: Changeset.t()
  def changeset(payment, :insert, params) do
    payment
    |> cast(params, writable_fields())
    |> validate()
    |> put_gross_amount_cents()
    |> put_net_amount_cents()
  end

  def changeset(payment, :update, params, locale \\ nil) do
    payment = Proxy.put_account(payment)
    default_locale = payment.account.default_locale
    locale = locale || default_locale
    castable_fields = castable_fields(:update, payment)

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

  defp castable_fields(:insert), do: writable_fields()

  defp castable_fields(:update, %{gateway: "freshcom"}) do
    [:captured_amount_cents, :status] ++ translatable_fields()
  end

  defp castable_fields(:update, _), do: writable_fields()

  defp put_gross_amount_cents(changeset = %{changes: %{amount_cents: amount_cents}}) do
    refunded_amount_cents = get_field(changeset, :refunded_amount_cents)
    put_change(changeset, :gross_amount_cents, amount_cents - refunded_amount_cents)
  end

  defp put_gross_amount_cents(changeset), do: changeset

  defp put_net_amount_cents(changeset = %{changes: %{amount_cents: _}}) do
    gross_amount_cents = get_field(changeset, :gross_amount_cents)
    processor_fee_cents = get_field(changeset, :processor_fee_cents)
    refunded_processor_fee_cents = get_field(changeset, :refunded_processor_fee_cents)
    freshcom_fee_cents = get_field(changeset, :freshcom_fee_cents)
    refunded_freshcom_fee_cents = get_field(changeset, :refunded_freshcom_fee_cents)

    net_amount_cents = gross_amount_cents - processor_fee_cents + refunded_processor_fee_cents - freshcom_fee_cents + refunded_freshcom_fee_cents
    put_change(changeset, :net_amount_cents, net_amount_cents)
  end

  defp put_net_amount_cents(changeset), do: changeset

  @spec validate(Changeset.t()) :: Changeset.t()
  def validate(changeset = %{action: :delete}) do
    gateway = get_field(changeset, :gateway)

    if gateway == "freshcom" do
      add_error(changeset, :gateway, "must be custom", code: :must_be_custom)
    else
      changeset
    end
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields(changeset))
    |> validate_capture_amount_cents()
  end

  defp required_fields(changeset) do
    status = get_field(changeset, :status)
    gateway = get_field(changeset, :gateway)
    common = [:status, :gateway, :amount_cents]

    cond do
      gateway == "online" -> common ++ [:processor]
      status == "pending" -> common
      gateway == "offline" && status == "paid" -> common ++ [:method]
      true -> common
    end
  end

  defp validate_capture_amount_cents(
         changeset = %{
           data: %{status: "authorized", gateway: "freshcom"},
           changes: %{capture_amount_cents: capture_amount_cents}
         }
       ) do
    authorized_amount_cents = get_field(changeset, :amount_cents)

    case capture_amount_cents > authorized_amount_cents do
      true ->
        add_error(
          changeset,
          :capture_amount_cents,
          "Capture amount cannot be greater than authorized amount",
          code: "cannot_be_gt_authorized_amount"
        )

      _ ->
        changeset
    end
  end

  defp validate_capture_amount_cents(changeset), do: changeset

  @spec sync_from_refund(__MODULE__.t(), Refund.t()) :: __MODULE__.t()
  def sync_from_refund(payment, refund) do
    refunded_amount_cents = payment.refunded_amount_cents + refund.amount_cents

    refunded_processor_fee_cents =
      payment.refunded_processor_fee_cents + refund.processor_fee_cents

    refunded_freshcom_fee_cents = payment.refunded_freshcom_fee_cents + refund.freshcom_fee_cents
    gross_amount_cents = payment.amount_cents - refunded_amount_cents

    net_amount_cents =
      gross_amount_cents - payment.processor_fee_cents + refunded_processor_fee_cents -
        payment.freshcom_fee_cents + refunded_freshcom_fee_cents

    payment_status =
      cond do
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
  Add the Stripe customer ID from the payment owner to the changeset.

  If the owner does not have a corresponding Stripe customer ID yet, then a
  Stripe customer will be created for the owner and the newly created
  Stripe customer ID will be added.
  """
  @spec put_stripe_customer_id(Changeset.t()) :: {:ok, Changeset.t()} | {:error, map}
  def put_stripe_customer_id(%{changes: %{source: _}} = changeset) do
    account = get_field(changeset, :account)
    owner_id = get_field(changeset, :owner_id)
    owner_type = get_field(changeset, :owner_type)

    owner =
      %{account: account, owner_id: owner_id, owner_type: owner_type}
      |> Proxy.get_owner()

    changeset = put_stripe_customer_id(changeset, owner)
    {:ok, changeset}
  end

  def put_stripe_customer_id(changeset), do: {:ok, changeset}

  defp put_stripe_customer_id(changeset, nil), do: changeset

  defp put_stripe_customer_id(changeset, %{stripe_customer_id: nil} = owner) do
    owner_type = get_field(changeset, :owner_type)

    with {:ok, stripe_customer} <- Proxy.create_stripe_customer(owner, owner_type),
         {:ok, owner} <-
           Proxy.update_owner(owner_type, owner, %{stripe_customer_id: stripe_customer["id"]}) do
      put_change(changeset, :stripe_customer_id, owner.stripe_customer_id)
    end
  end

  defp put_stripe_customer_id(changeset, owner) do
    put_change(changeset, :stripe_customer_id, owner.stripe_customer_id)
  end

  @doc """
  Process the given payment using the corresponding gateway and processor.

  This function may change the payment in the database.

  Returns the processed payment.

  The given `payment` should be a payment that is just created/updated using the `changeset`.
  """
  @spec process(__MODULE__.t(), Changeset.t()) :: {:ok, __MODULE__.t()} | {:error, map}
  def process(%{gateway: "freshcom", source: nil} = payment, %{
        data: %{amount_cents: nil},
        changes: %{amount_cents: _}
      }) do
    send_paylink(payment)
  end

  def process(%{gateway: "freshcom"} = payment, %{
        data: %{amount_cents: nil},
        changes: %{amount_cents: _}
      }) do
    charge(payment)
  end

  def process(%{gateway: "freshcom"} = payment, %{
        data: %{status: "authorized", capture_amount_cents: nil},
        changes: %{capture_amount_cents: _}
      }) do
    capture(payment)
  end

  def process(payment, _) do
    {:ok, payment}
  end

  @doc """
  Charge the given payment using its processor. If this payment is associated
  with a owner and was not saved previously, it will be saved for that owner.

  Returns `{:ok, processed_payment}` if successful.
  """
  @spec charge(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, map}
  def charge(payment = %__MODULE__{processor: "stripe"}) do
    settings = Settings.for_account(payment.account_id)

    stripe_data = %{source: payment.source, customer_id: payment.stripe_customer_id}
    card_status = if payment.save_source, do: "saved_by_owner", else: "kept_by_system"

    card_fields = %{
      status: card_status,
      owner_id: payment.owner_id,
      owner_type: payment.owner_type
    }

    payment = put_destination_amount_cents(payment, settings)

    with {:ok, source} <-
           Card.keep_stripe_source(stripe_data, card_fields, %{account: payment.account}),
         {:ok, stripe_charge} <-
           Proxy.create_stripe_charge(payment, source, settings.stripe_user_id) do
      sync_from_stripe_charge(payment, stripe_charge)
    else
      {:error, %{errors: _} = errors} ->
        {:error, errors}

      {:error, stripe_errors} ->
        {:error, format_stripe_errors(stripe_errors)}
    end
  end

  defp get_destination_amount_cents(payment, settings) do
    payment.amount_cents - get_processor_fee_cents(payment, settings) -
      get_freshcom_fee_cents(payment, settings)
  end

  defp put_destination_amount_cents(payment, settings) do
    Map.put(payment, :destination_amount_cents, get_destination_amount_cents(payment, settings))
  end

  defp get_processor_fee_cents(%{amount_cents: amount_cents, processor: "stripe"}, settings) do
    variable_rate = settings.stripe_variable_fee_percentage |> D.div(D.new(100))

    variable_fee_cents =
      D.new(amount_cents) |> D.mult(variable_rate) |> D.round() |> D.to_integer()

    variable_fee_cents + settings.stripe_fixed_fee_cents
  end

  defp get_freshcom_fee_cents(%{amount_cents: amount_cents}, settings) do
    rate = settings.freshcom_transaction_fee_percentage |> D.div(D.new(100))
    D.new(amount_cents) |> D.mult(rate) |> D.round() |> D.to_integer()
  end

  defp sync_from_stripe_charge(
         payment,
         %{"captured" => true, "amount" => amount_cents} = stripe_charge
       ) do
    processor_fee_cents = stripe_charge["balance_transaction"]["fee"]

    freshcom_fee_cents =
      stripe_charge["amount"] - stripe_charge["transfer"]["amount"] - processor_fee_cents

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

  defp sync_from_stripe_charge(payment, %{
         "captured" => false,
         "id" => stripe_charge_id,
         "amount" => authorized_amount_cents
       }) do
    payment =
      payment
      |> change(
        stripe_charge_id: stripe_charge_id,
        status: "authorized",
        authorized_amount_cents: authorized_amount_cents
      )
      |> Repo.update!()

    {:ok, payment}
  end

  @doc """
  This function capture an authorized payment. This function does not check
  whether the payment is actually authorized, it is up to the caller to make
  sure the payment is a valid authorized payment before passing it to this function.
  """
  @spec capture(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, map}
  def capture(%{processor: "stripe"} = payment) do
    with {:ok, _} <- Proxy.capture_stripe_charge(payment) do
      payment =
        payment
        |> change(status: "paid")
        |> Repo.update!()

      {:ok, payment}
    else
      {:error, stripe_errors} ->
        {:error, format_stripe_errors(stripe_errors)}

      other ->
        other
    end
  end

  defp format_stripe_errors(%{} = stripe_errors) do
    %{errors: [source: {stripe_errors["error"]["message"], code: stripe_errors["error"]["code"]}]}
  end

  defp format_stripe_errors(stripe_errors), do: stripe_errors
end
