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

  alias BlueJet.Goods.IdentityService

  schema "stockables" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string, default: "active"
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

  @type t :: Ecto.Schema.t

  @system_fields [
    :id,
    :account_id,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  def translatable_fields do
    __MODULE__.__trans__(:fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required([:name, :unit_of_measure])
  end

  defp put_print_name(changeset = %{ changes: %{ print_name: _ } }), do: changeset

  defp put_print_name(changeset = %{ data: %{ print_name: nil }, valid?: true }) do
    put_change(changeset, :print_name, get_field(changeset, :name))
  end

  defp put_print_name(changeset), do: changeset

  def changeset(stockable, params, locale \\ nil, default_locale \\ nil) do
    stockable = %{ stockable | account: IdentityService.get_account(stockable) }
    default_locale = default_locale || stockable.account.default_locale
    locale = locale || default_locale

    stockable
    |> cast(params, writable_fields())
    |> validate()
    |> put_print_name()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

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

    alias BlueJet.Goods.Stockable

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
