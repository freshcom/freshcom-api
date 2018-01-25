defmodule BlueJet.Storefront.Unlock do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  alias BlueJet.Translation
  alias BlueJet.Storefront.Unlock
  alias BlueJet.Storefront.{GoodsService, CrmService, IdentityService}

  schema "unlocks" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :sort_index, :integer, default: 0
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

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
      :account_id,
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
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:unlockable_id, :customer_id]
  end

  def required_fields do
    [:unlockable_id, :customer_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields())
    |> unique_constraint(:unlockable_id, name: :unlocks_customer_id_unlockable_id_index)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(unlock, params, locale \\ nil, default_locale \\ nil) do
    unlock = %{ unlock | account: IdentityService.get_account(unlock) }
    default_locale = default_locale || unlock.account.default_locale
    locale = locale || default_locale

    unlock
    |> cast(params, castable_fields(unlock))
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  #
  # MARK: External Resources
  #
  def get_unlockable(%{ unlockable_id: nil }), do: nil
  def get_unlockable(%{ unlockable_id: unlockable_id, unlockable: nil }), do: GoodsService.get_unlockable(unlockable_id)
  def get_unlockable(%{ unlockable: unlockable }), do: unlockable

  def get_customer(%{ customer_id: nil }), do: nil
  def get_customer(%{ customer_id: customer_id, customer: nil }), do: CrmService.get_customer(customer_id)
  def get_customer(%{ customer: customer }), do: customer

  def put_external_resources(unlock, {:unlock, nil}, _) do
    %{ unlock | unlockable: get_unlockable(unlock) }
  end

  def put_external_resources(unlock, {:customer, nil}, _) do
    %{ unlock | customer: get_customer(unlock) }
  end

  def put_external_resources(unlock, _, _), do: unlock

  defmodule Query do
    use BlueJet, :query

    def default() do
      from(u in Unlock, order_by: [desc: u.inserted_at])
    end

    def for_account(query, account_id) do
      from(u in query, where: u.account_id == ^account_id)
    end

    def preloads(_, _) do
      []
    end
  end
end
