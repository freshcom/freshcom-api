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

  alias BlueJet.Distribution.IdentityService
  alias BlueJet.Distribution.FulfillmentLineItem

  schema "fulfillments" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

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
    |> validate_required([:source_id, :source_type])
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(fulfillment, params, locale \\ nil, default_locale \\ nil) do
    fulfillment = %{ fulfillment | account: get_account(fulfillment) }
    default_locale = default_locale || get_account(fulfillment).default_locale
    locale = locale || default_locale

    fulfillment
    |> cast(params, writable_fields())
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  ######
  # External Resources
  #####
  def get_account(fulfillment) do
    fulfillment.account || IdentityService.get_account(fulfillment)
  end

  use BlueJet.FileStorage.Macro,
    put_external_resources: :external_file_collection,
    field: :external_file_collections,
    owner_type: "Fulfillment"

  def put_external_resources(fulfillment, _, _), do: fulfillment

  defmodule Query do
    use BlueJet, :query

    alias BlueJet.Distribution.Fulfillment

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
