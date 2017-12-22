defmodule BlueJet.Goods.Stockable do
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :print_name,
    :unit_of_measure,
    :caption,
    :description,
    :specification,
    :storage_description,
    :custom_data
  ], container: :translations

  alias BlueJet.Translation

  alias BlueJet.Goods.Stockable

  schema "stockables" do
    field :account_id, Ecto.UUID
    field :status, :string, default: "draft"
    field :code, :string
    field :name, :string
    field :label, :string

    field :print_name, :string
    field :unit_of_measure, :string
    field :variable_weight, :boolean, default: false

    field :storage_type, :string
    field :storage_size, :integer
    field :stackable, :boolean, default: false

    field :specification, :string
    field :storage_description, :string

    field :caption, :string
    field :description, :string
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

  def validate(changeset) do
    changeset
    |> validate_required([:account_id, :status, :name, :unit_of_measure])
    |> foreign_key_constraint(:account_id)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params, locale \\ nil, default_locale \\ nil) do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> put_print_name()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  def put_print_name(changeset = %{ changes: %{ print_name: _ } }), do: changeset

  def put_print_name(changeset = %{ data: %{ print_name: nil }, valid?: true }) do
    put_change(changeset, :print_name, get_field(changeset, :name))
  end

  def put_print_name(changeset), do: changeset

  ######
  # External Resources
  #####
  use BlueJet.FileStorage.Macro,
    put_external_resources: :external_file,
    field: :avatar

  use BlueJet.FileStorage.Macro,
    put_external_resources: :external_file_collection,
    field: :external_file_collections,
    owner_type: "Stockable"

  def put_external_resources(stockable, _, _), do: stockable

  defmodule Query do
    use BlueJet, :query

    def default() do
      from(s in Stockable, order_by: [desc: :updated_at])
    end

    def for_account(query, account_id) do
      from(s in query, where: s.account_id == ^account_id)
    end

    def preloads(_, _) do
      []
    end
  end
end
