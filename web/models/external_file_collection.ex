defmodule BlueJet.ExternalFileCollection do
  use BlueJet.Web, :model
  use Trans, translates: [:name, :custom_data], container: :translations

  alias BlueJet.Translation

  schema "external_file_collections" do
    field :name, :string
    field :label, :string
    field :file_ids, {:array, Ecto.UUID}, default: []

    field :custom_data, :map, default: %{}
    field :translations, :map, defualt: %{}

    timestamps()

    belongs_to :account, BlueJet.Account
    belongs_to :sku, BlueJet.Sku
    belongs_to :unlockable, BlueJet.Unlockable
    has_many :files, BlueJet.ExternalFile
  end

  def translatable_fields do
    BlueJet.Sku.__trans__(:fields)
  end

  def castable_fields(_) do
    [:account_id, :name, :label, :file_ids, :sku_id, :custom_data]
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct = %{ __meta__: %{ state: state } }, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(state))
    |> validate_required([:account_id, :label])
    |> Translation.put_change(translatable_fields(), struct.translations, locale)
  end

  def put_files(struct) do
    %{ struct | files: files(struct) }
  end

  def files(struct) do
    file_ids = struct.file_ids
    from(ef in BlueJet.ExternalFile, where: ef.id in ^file_ids) |> BlueJet.Repo.all()
  end
end
