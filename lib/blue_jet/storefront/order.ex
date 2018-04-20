defmodule BlueJet.Storefront.Order do
  use BlueJet, :data

  use Trans, translates: [
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias BlueJet.Utils

  alias BlueJet.Storefront.OrderLineItem
  alias __MODULE__.Proxy

  schema "orders" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    # cart, opened, closed, cancelled
    field :status, :string, default: "cart"
    field :code, :string
    field :name, :string
    field :label, :string

    # pending, authorized, partially_authorized, partially_authorized, partially_paid, paid, over_paid, partially_refunded, refunded
    field :payment_status, :string, default: "pending"
    # pending, partially_fulfilled, fulfilled, partially_returned, returned, discarded
    field :fulfillment_status, :string, default: "pending"
    field :fulfillment_method, :string
    field :system_tag, :string

    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :phone_number, :string

    field :sub_total_cents, :integer, default: 0
    field :tax_one_cents, :integer, default: 0
    field :tax_two_cents, :integer, default: 0
    field :tax_three_cents, :integer, default: 0
    field :grand_total_cents, :integer, default: 0
    field :authorization_total_cents, :integer, default: 0
    field :is_estimate, :boolean, default: false

    field :delivery_address_line_one, :string
    field :delivery_address_line_two, :string
    field :delivery_address_province, :string
    field :delivery_address_city, :string
    field :delivery_address_country_code, :string
    field :delivery_address_postal_code, :string

    field :opened_at, :utc_datetime
    field :confirmation_email_sent_at, :utc_datetime
    field :receipt_email_sent_at, :utc_datetime

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :customer_id, Ecto.UUID
    field :customer, :map, virtual: true

    field :payments, :map, virtual: true

    field :user_id, Ecto.UUID

    timestamps()

    has_many :line_items, OrderLineItem
    has_many :root_line_items, OrderLineItem
  end

  @type t :: Ecto.Schema.t

  @system_fields [
    :account_id,
    :system_tag,
    :payment_status,
    :fulfillment_status,
    :sub_total_cents,
    :tax_one_cents,
    :tax_two_cents,
    :tax_three_cents,
    :grant_total_cents,
    :authorization_total_cents,
    :placed_at,
    :confirmation_email_sent_at,
    :receipt_email_sent_at,
    :created_by_id
  ]

  def delivery_address_fields do
    [
      :delivery_address_line_one,
      :delivery_address_line_two,
      :delivery_address_province,
      :delivery_address_city,
      :delivery_address_country_code,
      :delivery_address_postal_code
    ]
  end

  @doc """
  Returns a list of fields that is changable by user input.
  """
  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  @doc """
  Returns a list of fields that can be translated.
  """
  def translatable_fields do
    __MODULE__.__trans__(:fields)
  end

  defp required_fields(%{ action: :insert }), do: required_fields()

  defp required_fields(changeset = %{ action: :update }) do
    fulfillment_method = get_field(changeset, :fulfillment_method)

    case fulfillment_method do
      "ship" -> required_fields() ++ (delivery_address_fields() -- [:delivery_address_line_two])

      _ -> required_fields()
    end
  end

  defp required_fields, do: [:name, :status, :email, :fulfillment_method]

  defp validate_inventory(changeset) do
    changeset
  end

  defp validate_customer_id(changeset) do
    id = get_field(changeset, :id)
    customer_id = get_field(changeset, :customer_id)

    if customer_id do
      changeset
    else
      ordered_unlockable_count =
        OrderLineItem.Query.default()
        |> OrderLineItem.Query.for_order(id)
        |> OrderLineItem.Query.leaf_for_target_type("Unlockable")
        |> Repo.aggregate(:count, :id)

      ordered_depositable_count =
        OrderLineItem.Query.default()
        |> OrderLineItem.Query.for_order(id)
        |> OrderLineItem.Query.leaf_for_target_type("Depositable")
        |> Repo.aggregate(:count, :id)

      cond do
        ordered_unlockable_count > 0 -> add_error(changeset, :customer, "An order that contains unlockable must be associated to a customer.", [validation: :required_for_unlockable, full_error_message: true])
        ordered_depositable_count > 0 -> add_error(changeset, :customer, "An order that contains depositable must be associated to a customer.", [validation: :required_for_depositable, full_error_message: true])
        true -> changeset
      end
    end
  end

  def validate_no_payment(changeset = %{ data: order }) do
    payment_count = Proxy.count_payment(order)

    if payment_count == 0 do
      changeset
    else
      changeset
      |> add_error(:payments, "must be empty", [validation: :be_empty])
    end
  end

  @doc """
  Returns the validated changeset.
  """
  def validate(changeset = %{ action: :insert }) do
    changeset
  end

  def validate(changeset = %{ action: :update }) do
    required_fields = required_fields(changeset)

    changeset
    |> validate_required(required_fields)
    |> validate_format(:email, Application.get_env(:blue_jet, :email_regex))
    |> validate_inventory()
    |> validate_customer_id()
  end

  def validate(changeset = %{ action: :delete }) do
    changeset
    |> validate_no_payment()
  end

  defp castable_fields(_, :insert), do: writable_fields() -- [:status]
  defp castable_fields(_, :update), do: writable_fields()

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(order, :insert, params) do
    castable_fields = castable_fields(order, :insert)

    order
    |> cast(params, castable_fields)
    |> Map.put(:action, :insert)
    |> put_name()
    |> Utils.put_clean_email()
    |> validate()
  end

  def changeset(order, :update, params, locale \\ nil, default_locale \\ nil) do
    order = %{ order | account: Proxy.get_account(order) }
    default_locale = default_locale || order.account.default_locale
    locale = locale || default_locale

    order
    |> cast(params, castable_fields(order, :update))
    |> Map.put(:action, :update)
    |> put_name()
    |> Utils.put_clean_email()
    |> validate()
    |> put_opened_at()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  def changeset(order, :delete) do
    change(order)
    |> Map.put(:action, :delete)
    |> validate()
  end

  defp put_name(changeset = %{ changes: %{ name: _ } }), do: changeset

  defp put_name(changeset) do
    first_name = get_change(changeset, :first_name)
    last_name = get_change(changeset, :last_name)

    if first_name || last_name do
      first_name = get_field(changeset, :first_name)
      last_name = get_field(changeset, :last_name)
      put_change(changeset, :name, "#{first_name} #{last_name}")
    else
      changeset
    end
  end

  defp put_opened_at(changeset = %{ valid?: true, data: %{ status: "cart" }, changes: %{ status: "opened" } }) do
    put_change(changeset, :opened_at, Ecto.DateTime.utc())
  end

  defp put_opened_at(changeset), do: changeset

  @doc """
  Balance the order base on the root line items.

  Returns the balanced order.
  """
  def balance(struct) do
    query =
      struct
      |> Ecto.assoc(:root_line_items)
      |> OrderLineItem.Query.root()

    sub_total_cents = Repo.aggregate(query, :sum, :sub_total_cents) || 0
    tax_one_cents = Repo.aggregate(query, :sum, :tax_one_cents) || 0
    tax_two_cents = Repo.aggregate(query, :sum, :tax_two_cents) || 0
    tax_three_cents = Repo.aggregate(query, :sum, :tax_three_cents) || 0
    grand_total_cents = Repo.aggregate(query, :sum, :grand_total_cents) || 0
    authorization_total_cents = Repo.aggregate(query, :sum, :authorization_total_cents) || 0

    root_line_items = Repo.all(query)
    estimate_count = Enum.reduce(root_line_items, 0, fn(item, acc) ->
      if item.is_estimate do
        acc + 1
      else
        acc
      end
    end)

    is_estimate = if estimate_count > 0 do
      true
    else
      false
    end

    changeset = change(
      struct,
      sub_total_cents: sub_total_cents,
      tax_one_cents: tax_one_cents,
      tax_two_cents: tax_two_cents,
      tax_three_cents: tax_three_cents,
      grand_total_cents: grand_total_cents,
      authorization_total_cents: authorization_total_cents,
      is_estimate: is_estimate
    )
    Repo.update!(changeset)
  end

  @doc """
  Refresh the payment status of the order. Returns the updated order.
  """
  def refresh_payment_status(order) do
    order
    |> change(payment_status: get_payment_status(order))
    |> Repo.update!()
  end

  @doc """
  Returns the payment status of the given order base on its payments.

  It will always return the correct payment status where as the `payment_status`
  field of the order may not be up to date yet.
  """
  def get_payment_status(order) do
    payments = Proxy.list_payment(order)

    total_paid_amount_cents =
      payments
      |> Enum.filter(fn(payment) -> payment.status in ["paid", "partially_refunded", "refunded"] end)
      |> Enum.reduce(0, fn(payment, acc) -> acc + payment.amount_cents end)

    total_gross_amount_cents =
      payments
      |> Enum.filter(fn(payment) -> payment.status in ["paid", "partially_refunded"] end)
      |> Enum.reduce(0, fn(payment, acc) -> acc + payment.gross_amount_cents end)

    total_authorized_amount_cents =
      payments
      |> Enum.filter(fn(payment) -> payment.status == "authorized" end)
      |> Enum.reduce(0, fn(payment, acc) -> acc + payment.amount_cents end)

    total_refunded_amount_cents =
      payments
      |> Enum.filter(fn(payment) -> payment.status in ["partially_refunded", "refunded"] end)
      |> Enum.reduce(0, fn(payment, acc) -> acc + payment.refunded_amount_cents end)

    cond do
      (order.grand_total_cents > 0) && (total_paid_amount_cents == 0) && (total_authorized_amount_cents == 0) ->
        "pending"

      (order.grand_total_cents > 0) && (total_paid_amount_cents == 0) && (total_authorized_amount_cents > 0) && (total_authorized_amount_cents < order.authorization_total_cents) ->
        "partially_authorized"

      (order.grand_total_cents > 0) && (total_paid_amount_cents == 0) && (total_authorized_amount_cents > 0) && (total_authorized_amount_cents >= order.authorization_total_cents) ->
        "authorized"

      (order.grand_total_cents > 0) && (total_paid_amount_cents < order.grand_total_cents) && (total_gross_amount_cents > 0) && (total_gross_amount_cents < order.grand_total_cents) ->
        "partially_paid"

      (order.grand_total_cents > 0) && (total_gross_amount_cents > 0) && (total_gross_amount_cents == order.grand_total_cents) ->
        "paid"

      (order.grand_total_cents == 0) ->
        "paid"

      (order.grand_total_cents > 0) && (total_gross_amount_cents > 0) && (total_gross_amount_cents > order.grand_total_cents) ->
        "over_paid"

      (order.grand_total_cents > 0) && (total_paid_amount_cents >= order.grand_total_cents) && (total_gross_amount_cents > 0) && (total_refunded_amount_cents > 0) ->
        "partially_refunded"

      (order.grand_total_cents > 0) && (total_gross_amount_cents == 0) && (total_refunded_amount_cents > 0) ->
        "refunded"
    end
  end

  def refresh_fulfillment_status(order) do
    order
    |> change(fulfillment_status: get_fulfillment_status(order))
    |> Repo.update!()
  end

  def get_fulfillment_status(order) do
    root_line_items =
      OrderLineItem
      |> OrderLineItem.Query.for_order(order.id)
      |> OrderLineItem.Query.root()
      |> Repo.all()

    fulfillable_count = length(root_line_items)

    partially_fulfilled_count =
      root_line_items
      |> Enum.filter(fn(line_item) -> line_item.fulfillment_status == "partially_fulfilled" end)
      |> length()

    fulfilled_count =
      root_line_items
      |> Enum.filter(fn(line_item) -> line_item.fulfillment_status == "fulfilled" end)
      |> length()

    partially_returned_count =
      root_line_items
      |> Enum.filter(fn(line_item) -> line_item.fulfillment_status == "partially_returned" end)
      |> length()

    returned_count =
      root_line_items
      |> Enum.filter(fn(line_item) -> line_item.fulfillment_status == "returned" end)
      |> length()

    discarded_count =
      root_line_items
      |> Enum.filter(fn(line_item) -> line_item.fulfillment_status == "discarded" end)
      |> length()

    cond do
      (fulfilled_count == 0) && (returned_count == 0) && (discarded_count == 0) ->
        "pending"

      (returned_count == 0) && (partially_fulfilled_count > 0) ->
        "partially_fulfilled"

      (returned_count == 0) && (fulfilled_count > 0) && (fulfilled_count < fulfillable_count) ->
        "partially_fulfilled"

      (returned_count == 0) && (fulfilled_count > 0) && (fulfilled_count >= fulfillable_count) ->
        "fulfilled"

      partially_returned_count > 0 ->
        "partially_returned"

      (returned_count > 0) && (returned_count < fulfillable_count) ->
        "partially_returned"

      (returned_count > 0 ) && (returned_count >= fulfillable_count) ->
        "returned"

      discarded_count >= fulfillable_count ->
        "discarded"
    end
  end

  defp process_auto_fulfill(order, changeset) do
    af_line_items =
      OrderLineItem
      |> OrderLineItem.Query.for_order(order.id)
      |> OrderLineItem.Query.with_auto_fulfill()
      |> OrderLineItem.Query.leaf()
      |> Repo.all()

    package = Proxy.create_auto_fulfillment_package(order)
    af_results = Enum.map(af_line_items, fn(af_line_item) ->
      OrderLineItem.Proxy.create_fulfillment_item(af_line_item, package)
    end)

    error = Enum.find(af_results, fn({status, _}) ->
      status == :error
    end)

    case error do
      {:error, %{ errors: [target: {_, [code: :already_unlocked, full_error_message: true]}] }} ->
        changeset = add_error(changeset, :line_items, "Some line items have unlockables that are already unlocked", [code: :already_unlocked, full_error_message: true])
        {:error, changeset}

      nil ->
        {:ok, order}

      other ->
        other
    end
  end

  @doc """
  Process the given `order` so that other related resource can be created/updated.

  This function may change the order in database.
  """
  @spec process(__MODULE__.t, Changeset.t) :: {:ok, __MODULE__.t} | {:error, Changeset.t}
  def process(order, changeset = %{ action: :update, data: %{ status: "cart" }, changes: %{ status: "opened" } }) do
    order
    |> Proxy.put_account()
    |> Proxy.put_customer()
    |> process_auto_fulfill(changeset)
  end

  def process(order, _), do: {:ok, order}
end
