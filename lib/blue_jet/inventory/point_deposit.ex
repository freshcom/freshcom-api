defmodule BlueJet.Inventory.PointDeposit do
  use BlueJet, :data

  use Trans, translates: [:name, :print_name, :caption, :description, :custom_data], container: :translations

  alias BlueJet.Translation
  alias BlueJet.Inventory.PointDeposit
  alias BlueJet.FileStorage.ExternalFile
  alias BlueJet.FileStorage.ExternalFileCollection

  schema "point_deposits" do
    field :account_id, Ecto.UUID

    field :code, :string
    field :status, :string
    field :name, :string
    field :print_name, :string
    field :amount, :integer

    field :caption, :string
    field :description, :string

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
    PointDeposit.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    PointDeposit.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required([:account_id, :status, :name, :print_name, :amount])
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
    |> Translation.put_change(translatable_fields(), locale)
  end

  def query() do
    from(u in PointDeposit, order_by: [desc: u.updated_at])
  end

  defmodule Query do
    use BlueJet, :query

    def for_account(query, account_id) do
      from(pd in query, where: pd.account_id == ^account_id)
    end

    def preloads(:avatar) do
      [avatar: ExternalFile.Query.default()]
    end

    def preloads(:external_file_collections) do
      [external_file_collections: ExternalFileCollection.Query.for_owner_type("PointDeposit")]
    end

    def default() do
      from(pd in PointDeposit, order_by: [desc: :updated_at])
    end
  end
end
