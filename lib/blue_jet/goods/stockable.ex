defmodule BlueJet.Goods.Stockable do
  use BlueJet, :data

  use Trans, translates: [:name, :print_name, :caption, :description, :specification, :storage_description, :custom_data], container: :translations

  alias BlueJet.Translation
  alias BlueJet.AccessRequest
  alias BlueJet.FileStorage

  alias BlueJet.Goods.Stockable

  schema "stockables" do
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

    field :avatar_id, Ecto.UUID
    field :avatar, :map, virtual: true
    field :external_file_collections, {:array, :map}, virtual: true, default: []

    timestamps()
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    Stockable.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    Stockable.__trans__(:fields)
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

  def put_external_resources(stockable = %Stockable{ avatar_id: nil }, :avatar) do
    stockable
  end
  def put_external_resources(stockable, :avatar) do
    {:ok, %{ data: avatar }} = FileStorage.do_get_external_file(%AccessRequest{
      vas: %{ account_id: stockable.account_id },
      params: %{ id: stockable.avatar_id }
    })

    %{ stockable | avatar: avatar }
  end
  def put_external_resources(stockable, :external_file_collections) do
    {:ok, %{ data: efcs }} = FileStorage.do_list_external_file_collection(%AccessRequest{
      vas: %{ account_id: stockable.account_id },
      filter: %{ owner_id: stockable.id, owner_type: "Stockable" },
      pagination: %{ size: 5, number: 1 }
    })

    %{ stockable | external_file_collections: efcs }
  end

  defmodule Query do
    use BlueJet, :query

    def for_account(query, account_id) do
      from(s in query, where: s.account_id == ^account_id)
    end

    def preloads(_) do
      []
    end

    def default() do
      from(s in Stockable, order_by: [desc: :updated_at])
    end
  end
end
