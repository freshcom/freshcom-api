defmodule BlueJet.Notification.EmailTemplate do
  use BlueJet, :data

  alias BlueJet.Notification.Email

  schema "email_templates" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true
    field :system_label, :string

    field :name, :string
    field :content, :string
    field :description, :string

    timestamps()

    has_many :email, Email, foreign_key: :template_id
  end

  def system_fields do
    [
      :id,
      :account_id,
      :system_label,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    __MODULE__.__schema__(:fields) -- system_fields()
  end

  def castable_fields() do
    [:name, :content, :description]
  end

  def validate(changeset) do
    changeset
    |> validate_required([:account_id, :name, :content])
    |> foreign_key_constraint(:account_id)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, castable_fields())
    |> validate()
  end

  defmodule Query do
    use BlueJet, :query

    alias BlueJet.Notification.EmailTemplate

    def default() do
      from(et in EmailTemplate, order_by: [desc: :updated_at])
    end

    def for_account(query, account_id) do
      from(et in query, where: et.account_id == ^account_id)
    end

    def preloads(_, _) do
      []
    end
  end
end
