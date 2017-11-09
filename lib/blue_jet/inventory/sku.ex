defmodule BlueJet.Inventory.Sku do
  use BlueJet, :data

  use Trans, translates: [:name, :print_name, :caption, :description, :specification, :storage_description, :custom_data], container: :translations

  alias BlueJet.Translation
  alias BlueJet.Inventory.Sku
  alias BlueJet.FileStorage.ExternalFile
  alias BlueJet.FileStorage.ExternalFileCollection

  schema "skus" do
    field :account_id, Ecto.UUID

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

    belongs_to :avatar, ExternalFile
    has_many :external_file_collections, ExternalFileCollection, foreign_key: :owner_id
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
    |> Translation.put_change(translatable_fields(), locale)
  end

  defmodule Query do
    use BlueJet, :query

    def for_account(query, account_id) do
      from(s in query, where: s.account_id == ^account_id)
    end

    def preloads(:avatar) do
      [avatar: ExternalFile.Query.default()]
    end

    def preloads(:external_file_collections) do
      [external_file_collections: ExternalFileCollection.Query.for_owner_type("Sku")]
    end

    def default() do
      from(s in Sku, order_by: [desc: :updated_at])
    end
  end
end
