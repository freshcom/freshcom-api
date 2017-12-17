defmodule BlueJet.Goods.Unlockable do
  use BlueJet, :data

  use Trans, translates: [:name, :print_name, :caption, :description, :custom_data], container: :translations

  alias BlueJet.Translation
  alias BlueJet.AccessRequest
  alias BlueJet.FileStorage

  alias BlueJet.Goods.Unlockable

  schema "unlockables" do
    field :account_id, Ecto.UUID

    field :code, :string
    field :status, :string, default: "active"
    field :name, :string
    field :print_name, :string

    field :caption, :string
    field :description, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :avatar_id, Ecto.UUID
    field :avatar, :map, virtual: true
    field :external_file_collections, {:array, :map}, virtual: true, default: []

    timestamps()
  end

  def system_fields do
    [
      :id,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    Unlockable.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    Unlockable.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required([:account_id, :status, :name])
    |> foreign_key_constraint(:account_id)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, locale \\ "en") do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> put_print_name()
    |> Translation.put_change(translatable_fields(), locale)
  end

  def put_print_name(changeset = %{ changes: %{ print_name: _ } }), do: changeset
  def put_print_name(changeset = %{ data: %{ print_name: nil }, valid?: true }) do
    put_change(changeset, :print_name, get_field(changeset, :name))
  end
  def put_print_name(changeset), do: changeset

  def put_external_resources(unlockable = %Unlockable{ avatar_id: nil }, :avatar) do
    unlockable
  end
  def put_external_resources(unlockable, :avatar) do
    {:ok, %{ data: avatar }} = FileStorage.do_get_external_file(%AccessRequest{
      vas: %{ account_id: unlockable.account_id },
      params: %{ id: unlockable.avatar_id }
    })

    %{ unlockable | avatar: avatar }
  end
  def put_external_resources(unlockable, :external_file_collections) do
    {:ok, %{ data: efcs }} = FileStorage.do_list_external_file_collection(%AccessRequest{
      vas: %{ account_id: unlockable.account_id },
      filter: %{ owner_id: unlockable.id, owner_type: "Unlockable" },
      pagination: %{ size: 5, number: 1 }
    })

    %{ unlockable | external_file_collections: efcs }
  end
  def put_external_resources(unlockable, {:external_file_collections, efc_preloads}) do
    {:ok, %{ data: efcs }} = FileStorage.do_list_external_file_collection(%AccessRequest{
      vas: %{ account_id: unlockable.account_id },
      filter: %{ owner_id: unlockable.id, owner_type: "Unlockable" },
      pagination: %{ size: 5, number: 1 },
      preloads: [efc_preloads]
    })

    %{ unlockable | external_file_collections: efcs }
  end

  defmodule Query do
    use BlueJet, :query

    def for_account(query, account_id) do
      from(u in query, where: u.account_id == ^account_id)
    end

    def preloads(_) do
      []
    end

    def default() do
      from(u in Unlockable, order_by: [desc: :updated_at])
    end
  end
end