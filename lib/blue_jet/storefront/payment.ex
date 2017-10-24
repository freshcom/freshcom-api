defmodule BlueJet.Storefront.Payment do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  alias Ecto.Changeset
  alias BlueJet.Translation
  alias BlueJet.Storefront.Payment
  alias BlueJet.Storefront.Refund
  alias BlueJet.Storefront.Order
  alias BlueJet.Identity.Account

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
    Payment.__schema__(:fields) -- system_fields()
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
end
