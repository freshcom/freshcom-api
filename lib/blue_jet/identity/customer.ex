defmodule BlueJet.Identity.Customer do
  use BlueJet, :data

  use Trans, translates: [:custom_data], container: :translations

  alias BlueJet.Translation
  alias BlueJet.Identity.Account
  alias BlueJet.Identity.RefreshToken
  alias BlueJet.Identity.Customer
  alias BlueJet.Storefront.Unlock
  alias BlueJet.Storefront.Order
  alias BlueJet.FileStorage.ExternalFileCollection

  @type t :: Ecto.Schema.t

  schema "customers" do
    field :code, :string
    field :status, :string, default: "anonymous"
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :encrypted_password, :string
    field :label, :string
    field :display_name, :string
    field :phone_number, :string

    field :password, :string, virtual: true

    field :stripe_customer_id, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :account, Account
    has_one :refresh_token, RefreshToken
    has_many :external_file_collections, ExternalFileCollection
    has_many :unlocks, Unlock
    has_many :unlockables, through: [:unlocks, :unlockable]
    has_many :orders, Order
  end

  def system_fields do
    [
      :id,
      :encrypted_password,
      :stripe_customer_id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    (Customer.__schema__(:fields) -- system_fields()) ++ [:password]
  end

  def translatable_fields do
    Customer.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id]
  end

  def required_fields(changeset) do
    status = get_field(changeset, :status)

    case status do
      "anonymous" -> [:account_id, :status]
      "internal" -> [:account_id, :status]
      "registered" -> writable_fields() -- [:display_name, :code, :phone_number, :label]
    end
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields(changeset))
    |> validate_length(:password, min: 8)
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
    |> foreign_key_constraint(:account_id)
    |> unique_constraint(:email)
  end

  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> put_encrypted_password()
    |> Translation.put_change(translatable_fields(), locale)
  end

  defp put_encrypted_password(changeset = %Ecto.Changeset{ valid?: true, changes: %{ password: password } })  do
    put_change(changeset, :encrypted_password, Comeonin.Bcrypt.hashpwsalt(password))
  end
  defp put_encrypted_password(changeset), do: changeset

  def preload(struct_or_structs, targets) when length(targets) == 0 do
    struct_or_structs
  end
  def preload(struct_or_structs, targets) when is_list(targets) do
    [target | rest] = targets

    struct_or_structs
    |> Repo.preload(preload_keyword(target))
    |> Customer.preload(rest)
  end

  def preload_keyword(:orders) do
    [orders: Order.query()]
  end
  def preload_keyword(:unlocks) do
    [unlocks: Unlock.query()]
  end
  def preload_keyword({:unlocks, unlock_preloads}) do
    [unlocks: {Unlock.query(), Unlock.preload_keyword(unlock_preloads)}]
  end
  def preload_keyword(:external_file_collections) do
    [external_file_collections: ExternalFileCollection.query()]
  end
end
