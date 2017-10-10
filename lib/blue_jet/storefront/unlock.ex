defmodule BlueJet.Storefront.Unlock do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  alias Ecto.Changeset
  alias BlueJet.Translation
  alias BlueJet.Storefront.Unlock
  alias BlueJet.Identity.Account
  alias BlueJet.Identity.Customer
  alias BlueJet.Inventory.Unlockable

  schema "unlocks" do
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :account, Account
    belongs_to :unlockable, Unlockable
    belongs_to :customer, Customer
  end

  def source(struct) do
    struct.sku || struct.unlockable
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    Unlock.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    Unlock.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields() -- [:status]
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id, :unlockable_id]
  end

  def required_fields do
    [:unlockable_id, :account_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields())
    |> foreign_key_constraint(:account_id)
    |> validate_assoc_account_scope([:unlockable, :customer])
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> Translation.put_change(translatable_fields(), locale)
  end

  def query() do
    from(u in Unlock, order_by: [desc: u.inserted_at])
  end

  def preload_keyword(:unlockable) do
    [unlockable: Unlockable.query()]
  end
end
