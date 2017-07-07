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
    has_many :file_memberships, BlueJet.ExternalFileCollectionMembership, foreign_key: :collection_id
    has_many :files, through: [:file_memberships, :file]
  end

  def translatable_fields do
    BlueJet.Sku.__trans__(:fields)
  end

  def castable_fields(_) do
    [:account_id, :name, :label, :sku_id, :custom_data]
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct = %{ __meta__: %{ state: state } }, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(state))
    |> validate_required([:account_id, :label])
    |> Translation.put_change(translatable_fields(), struct.translations, locale)
  end
end
