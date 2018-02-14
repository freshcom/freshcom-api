defmodule BlueJet.Fulfillment.ReturnPackage do
  @moduledoc """
  """
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias BlueJet.Fulfillment.IdentityService
  alias BlueJet.Fulfillment.ReturnPackage.Proxy
  alias BlueJet.Fulfillment.ReturnItem

  schema "return_packages" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :code, :string
    field :name, :string
    field :label, :string
    field :system_label, :string

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :order_id, Ecto.UUID
    field :order, :map, virtual: true

    field :customer_id, Ecto.UUID
    field :customer, :map, virtual: true

    field :file_collections, {:array, :map}, default: [], virtual: true

    timestamps()

    has_many :items, ReturnItem, foreign_key: :package_id
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
    |> validate_required([:order_id])
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(return_package, :insert, params) do
    return_package
    |> cast(params, writable_fields())
    |> validate()
  end

  def changeset(return_package, params, locale \\ nil, default_locale \\ nil) do
    return_package = Proxy.put_account(return_package)
    default_locale = default_locale || return_package.account.default_locale
    locale = locale || default_locale

    return_package
    |> cast(params, writable_fields())
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end
end
