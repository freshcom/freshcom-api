defmodule BlueJet.Sku do
  use BlueJet.Web, :model
  use Trans, translates: [:name, :print_name, :caption, :description, :specification, :storage_description, :custom_data], container: :translations

  alias BlueJet.Translation
  alias BlueJet.Account

  schema "skus" do
    field :code, :string
    field :status, :string
    field :name, :string
    field :print_name, :string
    field :unit_of_measure, :string
    field :variable_weight, :boolean, default: false

    field :storage_type, :string
    field :storage_size, :integer
    field :stackable, :boolean, default: false

    field :caption, :string
    field :description, :string
    field :specification, :string
    field :storage_description, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :avatar, BlueJet.ExternalFile
    belongs_to :account, Account
    has_many :external_file_collections, BlueJet.ExternalFileCollection
  end

  def translatable_fields do
    BlueJet.Sku.__trans__(:fields)
  end

  def castable_fields(state) do
    all = [:account_id, :code, :status, :name, :print_name, :unit_of_measure,
     :variable_weight, :storage_type, :storage_size, :stackable,
     :caption, :description, :specification, :storage_description,
     :avatar_id, :custom_data]

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
    |> validate_length(:print_name, min: 3)
    |> validate_required([:account_id, :status, :name, :print_name, :unit_of_measure])
    |> Translation.put_change(translatable_fields(), struct.translations, locale)
  end
end
