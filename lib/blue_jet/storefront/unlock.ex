defmodule BlueJet.Storefront.Unlock do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  alias BlueJet.Storefront.IdentityService

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

  @system_fields [
    :id,
    :account_id,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  def translatable_fields do
    __MODULE__.__trans__(:fields)
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

  defmodule Proxy do
    use BlueJet, :proxy

    alias BlueJet.{Goods, Crm}

    def put(unlock = %{ unlockable_id: unlockable_id }, {:unlockable, unlockable_preloads}, %{ account: account, locale: locale }) do
      {:ok, %{ data: unlockable }} = Goods.do_get_unlockable(%AccessRequest{
        account: account,
        params: %{ "id" => unlockable_id },
        locale: locale,
        preloads: unlockable_preloads || []
      })

      %{ unlock | unlockable: unlockable }
    end

    def put(unlock = %{ customer_id: customer_id }, {:customer, customer_preloads}, %{ account: account, locale: locale }) do
      {:ok, %{ data: customer }} = Crm.do_get_customer(%AccessRequest{
        account: account,
        params: %{ "id" => customer_id },
        locale: locale,
        preloads: customer_preloads || []
      })

      %{ unlock | customer: customer }
    end

    def put(unlock, _, _), do: unlock
  end

  defmodule Query do
    use BlueJet, :query

    alias BlueJet.Storefront.Unlock

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
