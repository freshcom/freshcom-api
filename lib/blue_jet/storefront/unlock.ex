defmodule BlueJet.Storefront.Unlock do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  alias BlueJet.Translation
  alias BlueJet.AccessRequest

  alias BlueJet.Goods
  alias BlueJet.CRM

  alias BlueJet.Storefront.Unlock

  schema "unlocks" do
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :account_id, Ecto.UUID

    field :source_id, Ecto.UUID
    field :source_type, :string
    field :source, :map, virtual: true

    field :unlockable_id, Ecto.UUID
    field :unlockable, :map, virtual: true

    field :customer_id, Ecto.UUID
    field :customer, :map, virtual: true

    timestamps()
  end

  def source(struct) do
    struct.stockable || struct.unlockable
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

  def get_unlockable(%{ unlockable_id: nil }, _), do: nil
  def get_unlockable(%{ unlockable_id: unlockable_id, unlockable: nil }, options = %{ account: account, locale: locale }) do
    {:ok, %{ data: unlockable }} = Goods.do_get_unlockable(%AccessRequest{
      account: account,
      params: %{ "id" => unlockable_id },
      locale: locale,
      preloads: options[:preloads] || []
    })

    unlockable
  end
  def get_unlockable(%{ unlockable: unlockable }, _), do: unlockable

  def get_customer(%{ customer_id: nil }, _), do: nil
  def get_customer(%{ customer_id: customer_id, customer: nil }, %{ account: account, locale: locale }) do
    {:ok, %{ data: customer }} = CRM.do_get_customer(%AccessRequest{
      account: account,
      params: %{ "id" => customer_id },
      locale: locale
    })

    customer
  end
  def get_customer(%{ customer: customer }, _), do: customer

  def put_external_resources(unlock, {:unlockable, unlockable_preloads}, options) do
    %{ unlock | unlockable: get_unlockable(unlock, Map.put(options, :preloads, unlockable_preloads)) }
  end

  def put_external_resources(unlock, {:customer, nil}, options) do
    %{ unlock | customer: get_customer(unlock, options) }
  end

  def put_external_resources(order, _, _), do: order

  defmodule Query do
    use BlueJet, :query

    def for_account(query, account_id) do
      from(u in query, where: u.account_id == ^account_id)
    end

    def preloads(_, _) do
      []
    end

    def default() do
      from(u in Unlock, order_by: [desc: u.inserted_at])
    end
  end
end
