defmodule BlueJet.Identity.Role do
  use BlueJet, :data
  use Trans, translates: [:custom_data], container: :translations

  alias BlueJet.Identity.Role
  alias BlueJet.Identity.Account

  @type t :: Ecto.Schema.t

  schema "roles" do
    field :status, :string, default: "active"
    field :permissions, :map, default: %{}
    field :system_label, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :account, Account
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    Role.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    Role.__trans__(:fields)
  end

  def castable_fields(%Role{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(payment = %Role{ __meta__: %{ state: :loaded }}) do
    fields = writable_fields() -- [:account_id]
  end

  def required_fields(_) do
    [:account_id, :permissions]
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields(changeset))
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> Translation.put_change(translatable_fields(), locale)
  end

  defmodule Query do
    use BlueJet, :query

    def default() do
      from(a in Role, order_by: [desc: :inserted_at])
    end
  end
end
