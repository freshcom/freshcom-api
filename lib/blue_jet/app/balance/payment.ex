defmodule BlueJet.Balance.Payment do
  use BlueJet, :data

  alias Decimal, as: D
  alias Ecto.Changeset

  alias BlueJet.Balance.Refund
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
    |> cast(params, castable_fields(:insert))
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
    |> cast(params, castable_fields)
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
    [:capture_amount_cents, :status] ++ translatable_fields()
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
  Return `true` is payment is capturable, otherwise `false`.

  A payment is capturable if and only if its status is `"authorized"` and
  has `:capture_amount_cents` set to be a positive integer.
  """
  def capturable?(%{capture_amount_cents: nil}), do: false
  def capturable?(%{status: "authorized", capture_amount_cents: _}), do: true

  defp get_destination_amount_cents(payment, settings) do
    payment.amount_cents - get_processor_fee_cents(payment, settings) -
      get_freshcom_fee_cents(payment, settings)
  end

  def put_destination_amount_cents(payment, settings) do
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
end
