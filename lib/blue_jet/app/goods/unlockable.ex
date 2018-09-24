defmodule BlueJet.Goods.Unlockable do
  @behaviour BlueJet.Data

  use BlueJet, :data

  alias __MODULE__.Proxy

  schema "unlockables" do
    field :account_id, UUID
    field :account, :map, virtual: true

    field :status, :string, default: "draft"
    field :code, :string
    field :name, :string
    field :label, :string

    field :print_name, :string

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :avatar_id, UUID
    field :avatar, :map, virtual: true

    field :file_id, UUID
    field :file, :map, virtual: true

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

  @spec changeset(__MODULE__.t(), :insert) :: Changeset.t()
  def changeset(unlockable, action, fields)
  def changeset(unlockable, :insert, fields) do
    unlockable
    |> cast(fields, writable_fields())
    |> Map.put(:action, :insert)
    |> validate()
    |> put_print_name()
  end

  @spec changeset(__MODULE__.t(), :update, map, String.t()) :: Changeset.t()
  def changeset(unlockable, action, fields, locale \\ nil)
  def changeset(unlockable, :update, fields, locale) do
    unlockable = Proxy.put_account(unlockable)
    default_locale = unlockable.account.default_locale
    locale = locale || default_locale

    unlockable
    |> cast(fields, writable_fields())
    |> Map.put(:action, :update)
    |> validate()
    |> put_print_name()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  @spec changeset(__MODULE__.t(), :delete) :: Changeset.t()
  def changeset(unlockable, action)
  def changeset(unlockable, :delete) do
    change(unlockable)
    |> Map.put(:action, :delete)
  end

  @spec validate(Changeset.t()) :: Changeset.t()
  def validate(changeset) do
    changeset
    |> validate_required([:status, :name])
  end

  defp put_print_name(changeset = %{ changes: %{ print_name: _ } }), do: changeset

  defp put_print_name(changeset = %{ data: %{ print_name: nil }, valid?: true }) do
    put_change(changeset, :print_name, get_field(changeset, :name))
  end

  defp put_print_name(changeset), do: changeset
end
