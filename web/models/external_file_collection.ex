defmodule BlueJet.ExternalFileCollection do
  use BlueJet.Web, :model
  use Trans, translates: [:name, :custom_data], container: :translations

  alias BlueJet.Translation

  schema "external_file_collections" do
    field :name, :string
    field :label, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, defualt: %{}

    timestamps()

    belongs_to :account, BlueJet.Account
    belongs_to :sku, BlueJet.Sku
    belongs_to :unlockable, BlueJet.Unlockable
    belongs_to :product, BlueJet.Product
    has_many :file_memberships, BlueJet.ExternalFileCollectionMembership, foreign_key: :collection_id
    has_many :files, through: [:file_memberships, :file]
  end

  def fields do
    BlueJet.ExternalFileCollection.__schema__(:fields)
    -- [:id, :inserted_at, :updated_at]
  end

  def translatable_fields do
    BlueJet.ExternalFileCollection.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    fields() -- [:account_id]
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
    |> Translation.put_change(translatable_fields(), struct.translations, locale)
  end
end
