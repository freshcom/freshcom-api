defmodule BlueJet.Product do
  use BlueJet.Web, :model
  use Trans, translates: [:name, :caption, :description, :custom_data], container: :translations

  alias BlueJet.Translation

  schema "products" do
    field :name, :string
    field :status, :string
    field :item_mode, :string, default: "any"
    field :caption, :string
    field :description, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :account, BlueJet.Account
    belongs_to :avatar, BlueJet.ExternalFile
  end

  def translatable_fields do
    BlueJet.Sku.__trans__(:fields)
  end

  def castable_fields(state) do
    all = [:account_id, :status, :item_mode, :name, :caption, :description, :custom_data, :avatar_id]

    case state do
      :built -> all
      :loaded -> all -- [:account_id]
    end
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct = %{ __meta__: %{ state: state } }, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(state))
    |> validate_required([:account_id, :name, :status, :item_mode])
    |> Translation.put_change(translatable_fields(), struct.translations, locale)
  end
end
