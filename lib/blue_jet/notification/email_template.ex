defmodule BlueJet.Notification.EmailTemplate do
  use BlueJet, :data

  alias BlueJet.Notification.Email

  schema "email_templates" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true
    field :system_label, :string

    field :name, :string
    field :subject, :string
    field :to, :string
    field :reply_to, :string
    field :content_html, :string
    field :content_text, :string
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
    writable_fields()
  end

  def validate(changeset) do
    changeset
    |> validate_required([:account_id, :name, :to, :subject, :content_html])
    |> foreign_key_constraint(:account_id)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, castable_fields())
    |> validate()
  end

  def extract_variables("identity.password_reset_token.created", %{ account: account, user: user }) do
    %{
      user: Map.take(user, [:id, :password_reset_token, :first_name, :last_name, :email]),
      account: Map.take(account, [:name])
    }
  end

  def render_html(%{ content_html: content_html }, variables) do
    :bbmustache.render(content_html, variables, key_type: :atom)
  end

  def render_text(%{ content_text: nil }, _) do
    nil
  end

  def render_text(%{ content_text: content_text }, variables) do
    :bbmustache.render(content_text, variables, key_type: :atom)
  end

  def render_subject(%{ subject: subject }, variables) do
    :bbmustache.render(subject, variables, key_type: :atom)
  end

  def render_to(%{ to: to }, variables) do
    :bbmustache.render(to, variables, key_type: :atom)
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
