defmodule BlueJet.Price do
  use BlueJet.Web, :model
  use Trans, translates: [:name, :caption], container: :translations

  alias BlueJet.Translation

  schema "prices" do
    field :status, :string
    field :name, :string
    field :label, :string
    field :caption, :string
    field :currency_code, :string, default: "CAD"
    field :charge_amount_cents, :integer
    field :estimate_amount_cents, :integer
    field :maximum_amount_cents, :integer
    field :minimum_order_quantity, :integer, default: 1
    field :order_unit, :string
    field :charge_unit, :string
    field :public_orderable, :boolean, default: true
    field :estimate_by_default, :boolean, default: false
    field :tax_one_rate, :integer, default: 0
    field :tax_two_rate, :integer, default: 0
    field :tax_three_rate, :integer, default: 0
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :account, BlueJet.Account
    belongs_to :product_item, BlueJet.ProductItem
  end

  def translatable_fields do
    BlueJet.Price.__trans__(:fields)
  end

  def castable_fields(state) do
    all = [:account_id, :product_item_id, :status, :name, :caption, :currency_code,
     :charge_amount_cents, :estimate_amount_cents, :maximum_amount_cents, :minimum_order_quantity,
     :order_unit, :charge_unit, :public_orderable, :label, :estimate_by_default, :tax_one_rate,
     :tax_two_rate, :tax_three_rate, :start_time, :end_time, :custom_data]

    case state do
      :built -> all
      :loaded -> all -- [:account_id]
    end
  end

  def required_fields do
    [:account_id, :status, :label, :currency_code, :charge_amount_cents, :order_unit, :charge_unit]
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct = %{ __meta__: %{ state: state } }, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(state))
    |> validate_required(required_fields())
    |> Translation.put_change(translatable_fields(), struct.translations, locale)
  end
end
