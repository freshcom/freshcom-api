defmodule BlueJet.Distribution.Fulfillment do
  @moduledoc """
  """
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  import BlueJet.Identity.Shortcut

  alias BlueJet.Distribution.Fulfillment
  alias BlueJet.Distribution.FulfillmentLineItem

  @type t :: Ecto.Schema.t

  schema "fulfillments" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string, default: "pending"
    field :code, :string
    field :name, :string
    field :label, :string

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :source_id, Ecto.UUID
    field :source_type, :string
    field :source, :map, virtual: true

    field :external_file_collections, {:array, :map}, default: [], virtual: true

    timestamps()

    has_many :line_items, FulfillmentLineItem
  end

  def translatable_fields do
    Fulfillment.__trans__(:fields)
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    Fulfillment.__schema__(:fields) -- system_fields()
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end

  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required([:status, :source_id, :source_type, :account_id])
    |> foreign_key_constraint(:account_id)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params, locale \\ nil, default_locale \\ nil) do
    default_locale = default_locale || get_account(struct).default_locale
    locale = locale || default_locale

    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  ######
  # External Resources
  #####
  use BlueJet.FileStorage.Macro,
    put_external_resources: :external_file_collection,
    field: :external_file_collections,
    owner_type: "Fulfillment"

  defmodule Query do
    use BlueJet, :query

    def default() do
      from(f in Fulfillment, order_by: [desc: f.inserted_at])
    end

    def for_account(query, account_id) do
      from(f in query, where: f.account_id == ^account_id)
    end

    def preloads({:line_items, line_item_preloads}, options) do
      query = FulfillmentLineItem.Query.default()
      [line_items: {query, FulfillmentLineItem.Query.preloads(line_item_preloads, options)}]
    end

    def preloads(_, _) do
      []
    end
  end
end
