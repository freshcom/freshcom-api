defmodule BlueJet.Goods.Stockable.Default do
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  def schema do
    alias Ecto.UUID

    quote do
      field :account_id, UUID
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

      field :avatar_id, UUID
      field :avatar, :map, virtual: true

      field :file_collections, {:array, :map}, virtual: true, default: []

      timestamps()
    end
  end

  def impl do
    alias BlueJet.Translation
    alias BlueJet.Goods.Stockable.Proxy

    quote do
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
          :unit_of_measure,
          :caption,
          :description,
          :specification,
          :storage_description,
          :custom_data
        ]
      end

      @spec changeset(__MODULE__.t(), :insert, map) :: Changeset.t()
      def changeset(stockable, action, fields)
      def changeset(stockable, :insert, fields) do
        stockable
        |> cast(fields, writable_fields())
        |> Map.put(:action, :insert)
        |> validate()
        |> _put_print_name()
      end

      @spec changeset(__MODULE__.t(), :update, map, String.t()) :: Changeset.t()
      def changeset(stockable, action, fields, locale \\ nil)
      def changeset(stockable, :update, fields, locale) do
        stockable = Proxy.put_account(stockable)
        default_locale = stockable.account.default_locale
        locale = locale || default_locale

        stockable
        |> cast(fields, writable_fields())
        |> Map.put(:action, :update)
        |> validate()
        |> _put_print_name()
        |> Translation.put_change(translatable_fields(), locale, default_locale)
      end

      @spec changeset(__MODULE__.t(), :delete) :: Changeset.t()
      def changeset(stockable, action)
      def changeset(stockable, :delete) do
        change(stockable)
        |> Map.put(:action, :delete)
      end

      @spec validate(Changeset.t()) :: Changeset.t()
      def validate(changeset) do
        changeset
        |> validate_required([:name, :unit_of_measure])
      end

      defp _put_print_name(changeset = %{ changes: %{ print_name: _ } }), do: changeset

      defp _put_print_name(changeset = %{ data: %{ print_name: nil }, valid?: true }) do
        put_change(changeset, :print_name, get_field(changeset, :name))
      end

      defp _put_print_name(changeset), do: changeset

      defoverridable [
        validate: 1,
        changeset: 2,
        changeset: 3,
        changeset: 4
      ]
    end
  end
end


defmodule BlueJet.Goods.Stockable do
  @behaviour BlueJet.Data

  use BlueJet, :data
  alias __MODULE__.Default

  schema "stockables" do
    use Default, :schema
  end

  use Default, :impl
end


defmodule MyApp.Goods.Stockable do
  use BlueJet, :data
  alias BlueJet.Goods.Stockable.Default

  schema "stockables" do
    use Default, :schema

    field :supplier_name, :string, virtual: true
  end

  use Default, :impl

  def validate(changeset) do
    changeset
    |> validate_required([:supplier_name])
    |> super()
  end
end