defmodule BlueJet.Goods.Depositable do
  use BlueJet, :data

  use Trans, translates: [:name, :print_name, :caption, :description, :custom_data], container: :translations

  alias BlueJet.Translation
  alias BlueJet.AccessRequest
  alias BlueJet.FileStorage

  alias BlueJet.Goods.Depositable

  schema "depositables" do
    field :account_id, Ecto.UUID

    field :code, :string
    field :status, :string, default: "active"
    field :name, :string
    field :print_name, :string
    field :amount, :integer

    field :caption, :string
    field :description, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :target_type, :string

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
    Depositable.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    Depositable.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required([:account_id, :status, :name, :print_name, :amount])
    |> foreign_key_constraint(:account_id)
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

  def put_external_resources(depositable = %Depositable{ avatar_id: nil }, :avatar) do
    depositable
  end
  def put_external_resources(depositable, :avatar) do
    {:ok, %{ data: avatar }} = FileStorage.do_get_external_file(%AccessRequest{
      vas: %{ account_id: depositable.account_id },
      params: %{ id: depositable.avatar_id }
    })

    %{ depositable | avatar: avatar }
  end
  def put_external_resources(depositable, :external_file_collections) do
    {:ok, %{ data: efcs }} = FileStorage.do_list_external_file_collection(%AccessRequest{
      vas: %{ account_id: depositable.account_id },
      filter: %{ owner_id: depositable.id, owner_type: "Depositable" },
      pagination: %{ size: 5, number: 1 }
    })

    %{ depositable | external_file_collections: efcs }
  end

  defmodule Query do
    use BlueJet, :query

    def default() do
      from(d in Depositable, order_by: [desc: :updated_at])
    end

    def for_account(query, account_id) do
      from(d in query, where: d.account_id == ^account_id)
    end

    def preloads(_) do
      []
    end
  end
end
