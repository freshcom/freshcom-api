defmodule BlueJet.Distribution.FulfillmentLineItem do
  @moduledoc """
  """

  use BlueJet, :data

  use Trans, translates: [
    :name,
    :print_name,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias BlueJet.Distribution.FulfillmentLineItem

  schema "fulfillment_line_items" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :code, :string
    field :name, :string
    field :label, :string

    field :print_name, :string

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :source_id, Ecto.UUID
    field :source_type, :string
    field :source, :map, virtual: true

    field :goods_id, Ecto.UUID
    field :goods_type, :string
    field :goods, :map, virtual: true

    field :external_file_collections, {:array, :map}, default: [], virtual: true

    timestamps()

    belongs_to :fulfillment, Fulfillment
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    FulfillmentLineItem.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    FulfillmentLineItem.__trans__(:fields)
  end

  def castable_fields() do
    writable_fields() -- [:account_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required([:source_id, :source_type])
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params, locale \\ nil, default_locale \\ nil) do
    struct
    |> cast(params, castable_fields())
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  ####
  # External Resources
  ###

  use BlueJet.FileStorage.Macro,
    put_external_resources: :external_file_collection,
    field: :external_file_collections,
    owner_type: "FulfillmentLineItem"

  def put_external_resources(fli, _, _), do: fli

  defmodule Query do
    use BlueJet, :query

    def default() do
      from fli in FulfillmentLineItem
    end

    def for_account(query, account_id) do
      from(fli in query, where: fli.account_id == ^account_id)
    end

    def preloads(_, _) do
      []
    end
  end
end
