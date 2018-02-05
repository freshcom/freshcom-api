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

  alias BlueJet.Distribution.Fulfillment
  alias BlueJet.Distribution.IdentityService

  schema "fulfillment_line_items" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string, default: "pending"
    field :code, :string
    field :name, :string
    field :label, :string

    field :quantity, :integer
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

    field :file_collections, {:array, :map}, default: [], virtual: true

    timestamps()

    belongs_to :fulfillment, Fulfillment
  end

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
  def changeset(fli, params, locale \\ nil, default_locale \\ nil) do
    fli = %{ fli | account: get_account(fli) }
    default_locale = default_locale || fli.account.default_locale
    locale = locale || default_locale

    fli
    |> cast(params, writable_fields())
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  ####
  # External Resources
  ###
  def get_account(fli) do
    fli.account || IdentityService.get_account(fli)
  end

  use BlueJet.FileStorage.Macro,
    put_external_resources: :file_collection,
    field: :file_collections,
    owner_type: "FulfillmentLineItem"

  def put_external_resources(fli, _, _), do: fli

  defmodule Query do
    use BlueJet, :query

    alias BlueJet.Distribution.FulfillmentLineItem

    def default() do
      from fli in FulfillmentLineItem
    end

    def for_account(query, account_id) do
      from(fli in query, where: fli.account_id == ^account_id)
    end

    def for_source(query, source_type, source_id) do
      from fli in query,
        where: fli.source_type == ^source_type,
        where: fli.source_id == ^source_id
    end

    def preloads(_, _) do
      []
    end
  end
end
