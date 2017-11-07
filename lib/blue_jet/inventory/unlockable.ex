defmodule BlueJet.Inventory.Unlockable do
  use BlueJet, :data

  use Trans, translates: [:name, :print_name, :caption, :description, :custom_data], container: :translations

  alias BlueJet.Translation
  alias BlueJet.Identity.Account
  alias BlueJet.FileStorage.ExternalFile
  alias BlueJet.FileStorage.ExternalFileCollection
  alias BlueJet.Storefront.ProductItem
  alias BlueJet.Inventory.Unlockable

  schema "unlockables" do
    field :code, :string
    field :status, :string
    field :name, :string
    field :print_name, :string

    field :caption, :string
    field :description, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :account, Account
    belongs_to :avatar, ExternalFile
    has_many :external_file_collections, ExternalFileCollection, foreign_key: :owner_id
    has_many :product_items, ProductItem
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    Unlockable.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    Unlockable.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required([:account_id, :status, :name, :print_name])
    |> foreign_key_constraint(:account_id)
    |> validate_assoc_account_scope(:avatar)
  end

  def for_order(order) do
    order_id = order.id
    from(u in Unlockable, join: oli in OrderLineItem, where: oli.unlockable_id == u.id, where: oli.order_id == ^order_id) |> Repo.all()
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
    from(u in Unlockable, order_by: [desc: u.updated_at])
  end

  defmodule Query do
    use BlueJet, :query

    def for_account(query, account_id) do
      from(u in query, where: u.account_id == ^account_id)
    end

    def preloads(:avatar) do
      [avatar: ExternalFile.Query.default()]
    end

    def preloads(:external_file_collections) do
      [external_file_collections: ExternalFileCollection.Query.for_owner_type("unlockable")]
    end

    def default() do
      from(u in Unlockable, order_by: [desc: :updated_at])
    end
  end
end
