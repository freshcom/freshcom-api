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
  alias BlueJet.Distribution.FulfillmentLineItem.Proxy

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
  def changeset(fli, :insert, params) do
    fli
    |> cast(params, writable_fields())
    |> validate()
  end

  def changeset(fli, params, locale \\ nil, default_locale \\ nil) do
    fli = Proxy.put_account(fli)
    default_locale = default_locale || fli.account.default_locale
    locale = locale || default_locale

    fli
    |> cast(params, writable_fields())
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end
end
