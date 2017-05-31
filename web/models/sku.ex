defmodule BlueJet.Sku do
  use BlueJet.Web, :model
  use Trans, translates: [:name, :caption, :description, :specification, :storage_description, :custom_data], container: :translations

  alias BlueJet.Translation
  alias BlueJet.CustomData
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

  def castable_fields do
    [:account_id, :code, :status, :name, :print_name, :unit_of_measure,
     :variable_weight, :storage_type, :storage_size, :stackable,
     :caption, :description, :specification, :storage_description,
     :avatar_id, :custom_data]
  end

  def db_fields do
    BlueJet.Sku.__schema__(:fields)
  end

  def system_fields do
    Enum.uniq(db_fields() ++ castable_fields())
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, locale, params \\ %{}) do
    struct
    |> cast(params, castable_fields())
    |> validate_length(:print_name, min: 3)
    |> validate_required([:account_id, :status, :name, :print_name, :unit_of_measure])
    |> Translation.put_change(translatable_fields(), struct.translations, locale)
  end

  # def set_translations(changeset, params, old_translations, translatable_fields, locale) when locale !== "en" do
  #   t_fields = Enum.map_every(translatable_fields, 1, fn(item) -> Atom.to_string(item) end)
  #   nl_translations = old_translations
  #                   |> Map.get(locale, %{})
  #                   |> Map.merge(Map.take(params, t_fields))

  #   new_translations = Map.merge(old_translations, %{ locale => nl_translations })

  #   changeset = Enum.reduce(translatable_fields, changeset, fn(field_name, acc) -> Ecto.Changeset.delete_change(acc, field_name) end)
  #   Ecto.Changeset.put_change(changeset, :translations, new_translations)
  # end
  # def set_translations(changeset, _params, _old_translations, _translatable_fields, _locale), do: changeset
end
