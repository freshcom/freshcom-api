defmodule BlueJet.FileStorage.ExternalFileCollection do
  use BlueJet, :data

  use Trans, translates: [:name, :custom_data], container: :translations

  alias BlueJet.Translation
  alias BlueJet.FileStorage.ExternalFileCollection
  alias BlueJet.FileStorage.ExternalFileCollectionMembership
  alias BlueJet.Identity.Account
  alias BlueJet.Inventory.Sku
  alias BlueJet.Inventory.Unlockable
  alias BlueJet.Storefront.Product

  schema "external_file_collections" do
    field :name, :string
    field :label, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, defualt: %{}

    timestamps()

    belongs_to :account, Account
    belongs_to :sku, Sku
    belongs_to :unlockable, Unlockable
    belongs_to :product, Product
    has_many :file_memberships, ExternalFileCollectionMembership, foreign_key: :collection_id
    has_many :files, through: [:file_memberships, :file]
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    ExternalFileCollection.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    ExternalFileCollection.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required([:account_id, :label])
    |> foreign_key_constraint(:account_id)
    |> validate_assoc_account_scope([:sku, :unlockable, :product])
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

  def file_count(%ExternalFileCollection{ id: efc_id }) do
    from(efcm in ExternalFileCollectionMembership,
      select: count(efcm.id),
      where: efcm.collection_id == ^efc_id)
    |> Repo.one()
  end
end
