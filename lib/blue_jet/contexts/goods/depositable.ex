defmodule BlueJet.Goods.Depositable do
  use BlueJet, :data

  alias __MODULE__.Proxy

  schema "depositables" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string, default: "draft"
    field :code, :string
    field :name, :string
    field :label, :string

    field :print_name, :string
    field :amount, :integer
    field :gateway, :string

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :avatar_id, Ecto.UUID
    field :avatar, :map, virtual: true

    field :file_collections, {:array, :map}, virtual: true, default: []

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
    [
      :name,
      :print_name,
      :caption,
      :description,
      :custom_data
    ]
  end

  @spec changeset(__MODULE__.t(), atom, map) :: Changeset.t()
  def changeset(depositable, :insert, params) do
    depositable
    |> cast(params, writable_fields())
    |> Map.put(:action, :insert)
    |> validate()
    |> put_print_name()
  end

  @spec changeset(__MODULE__.t(), atom, map, String.t(), String.t()) :: Changeset.t()
  def changeset(depositable, :update, params, locale \\ nil, default_locale \\ nil) do
    depositable = Proxy.put_account(depositable)
    default_locale = default_locale || depositable.account.default_locale
    locale = locale || default_locale

    depositable
    |> cast(params, writable_fields())
    |> Map.put(:action, :update)
    |> validate()
    |> put_print_name()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  @spec changeset(__MODULE__.t(), atom) :: Changeset.t()
  def changeset(depositable, :delete) do
    change(depositable)
    |> Map.put(:action, :delete)
  end

  defp put_print_name(changeset = %{ changes: %{ print_name: _ } }), do: changeset

  defp put_print_name(changeset = %{ data: %{ print_name: nil }, valid?: true }) do
    put_change(changeset, :print_name, get_field(changeset, :name))
  end

  defp put_print_name(changeset), do: changeset

  defp validate(changeset) do
    changeset
    |> validate_required([:status, :name, :amount, :gateway])
  end
end
