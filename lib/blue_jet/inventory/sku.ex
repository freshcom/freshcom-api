defmodule BlueJet.Inventory.Sku do
  use BlueJet, :data

  use Trans, translates: [:name, :print_name, :caption, :description, :specification, :storage_description, :custom_data], container: :translations

  alias BlueJet.Translation
  alias BlueJet.Inventory.Sku
  alias BlueJet.Identity.Account
  alias BlueJet.FileStorage.ExternalFile
  alias BlueJet.FileStorage.ExternalFileCollection
  alias BlueJet.Storefront.ProductItem

  schema "skus" do
    field :code, :string
    field :status, :string
    field :name, :string
    field :print_name, :string
    field :unit_of_measure, :string
    field :variable_weight, :boolean, default: false

    field :storage_type, :string
    field :storage_size, :integer
    field :stackable, :boolean, default: false

    field :caption, :string
    field :description, :string
    field :specification, :string
    field :storage_description, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :account, Account
    belongs_to :avatar, ExternalFile
    has_many :external_file_collections, ExternalFileCollection
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
    Sku.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    Sku.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id]
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> validate_length(:print_name, min: 3)
    |> validate_required([:account_id, :status, :name, :print_name, :unit_of_measure])
    |> Translation.put_change(translatable_fields(), struct.translations, locale)
  end
end
