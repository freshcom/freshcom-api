defmodule BlueJet.Inventory.Unlockable do
  use BlueJet, :data

  use Trans, translates: [:name, :print_name, :caption, :description, :custom_data], container: :translations

  alias BlueJet.Translation

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

    belongs_to :account, BlueJet.Identity.Account
    belongs_to :avatar, BlueJet.FileStorage.ExternalFile
    has_many :external_file_collections, BlueJet.FileStorage.ExternalFileCollection
    has_many :product_items, BlueJet.Storefront.ProductItem
  end

  def fields do
    BlueJet.Inventory.Unlockable.__schema__(:fields)
    -- [:id, :inserted_at, :updated_at]
  end

  def translatable_fields do
    BlueJet.Inventory.Unlockable.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    fields() -- [:account_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required([:account_id, :status, :name, :print_name])
    |> foreign_key_constraint(:account_id)
    |> validate_assoc_account_scope(:avatar)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> Translation.put_change(translatable_fields(), struct.translations, locale)
  end
end
