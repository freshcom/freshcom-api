defmodule BlueJet.Unlockable do
  use BlueJet.Web, :model
  use Trans, translates: [:name, :print_name, :caption, :description, :custom_data], container: :translations

  alias BlueJet.Translation

  schema "unlockables" do
    field :code, :string
    field :status, :string
    field :name, :string
    field :print_name, :string

    field :caption, :string
    field :description, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :account, BlueJet.Account
    belongs_to :avatar, BlueJet.ExternalFile
    has_many :external_file_collections, BlueJet.ExternalFileCollection
  end

  def translatable_fields do
    BlueJet.Unlockable.__trans__(:fields)
  end

  def castable_fields(state) do
    all = [:account_id, :code, :status, :name, :print_name,
     :caption, :description, :avatar_id, :custom_data]

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
    |> validate_required([:account_id, :status, :name, :print_name])
    |> Translation.put_change(translatable_fields(), struct.translations, locale)
  end
end
