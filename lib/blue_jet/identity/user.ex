defmodule BlueJet.Identity.User do
  use BlueJet, :data

  alias BlueJet.Repo

  alias BlueJet.Identity.User
  alias BlueJet.Identity.Account
  alias BlueJet.Identity.RefreshToken
  alias BlueJet.Identity.AccountMembership

  schema "users" do
    field :status, :string
    field :username, :string
    field :email, :string
    field :encrypted_password, :string
    field :first_name, :string
    field :last_name, :string

    field :current_password, :string, virtual: true
    field :password, :string, virtual: true

    timestamps()

    field :role, :string, virtual: true

    belongs_to :default_account, Account
    belongs_to :account, Account
    has_many :refresh_tokens, RefreshToken
    has_many :account_memberships, AccountMembership
  end

  def system_fields do
    [
      :id,
      :default_account_id,
      :account_id,
      :encrypted_password,
      :inserted_at,
      :updated_at
    ]
  end

  @doc """
  Returns a list of fields that is changable by user input.
  """
  def writable_fields do
    (User.__schema__(:fields) -- system_fields()) ++ [:password, :current_password]
  end

  @doc """
  Returns a list of fields that can be changed for the given user.
  """
  def castable_fields(_), do: writable_fields()

  @doc """
  Returns a list of required fields for the given `changeset`
  """
  def required_fields(%{ data: %{ __meta__: %{ state: :built } } }), do: required_fields() ++ [:password]

  def required_fields(%{ data: %{ __meta__: %{ state: :loaded } }, changes: %{ password: _ } }) do
    required_fields() ++ [:current_password]
  end

  def required_fields(%{ data: %{ __meta__: %{ state: :loaded } } }), do: required_fields()

  def required_fields, do: [:email, :default_account_id]

  ##########
  defp validate_current_password(changeset = %{ changes: %{ password: _ } }) do
    encrypted_password = get_field(changeset, :encrypted_password)
    current_password = get_field(changeset, :current_password)

    if checkpw(current_password, encrypted_password) do
      changeset
    else
      add_error(changeset, :current_password, "is incorrect")
    end
  end

  defp validate_current_password(changeset), do: changeset

  defp checkpw(nil, _), do: false
  defp checkpw(_, nil), do: false
  defp checkpw(pp, ep), do: Comeonin.Bcrypt.checkpw(pp, ep)

  @doc """
  Returns the validated changeset.
  """
  def validate(changeset) do
    required_fields = required_fields(changeset)

    changeset
    |> validate_required(required_fields)
    |> validate_current_password()
    |> validate_length(:password, min: 8)
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
    |> foreign_key_constraint(:default_account_id)
    |> foreign_key_constraint(:account_id)
    |> unique_constraint(:email, name: :users_account_id_email_index)
    |> unique_constraint(:username, name: :users_account_id_username_index)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
    |> put_encrypted_password()
  end

  defp put_encrypted_password(changeset = %{ valid?: true, changes: %{ password: password } })  do
    put_change(changeset, :encrypted_password, Comeonin.Bcrypt.hashpwsalt(password))
  end
  defp put_encrypted_password(changeset), do: changeset

  def get_role(user, account) do
    membership = Repo.get_by(AccountMembership, user_id: user.id, account_id: account.id)

    if membership do
      membership.role
    else
      nil
    end
  end

  def put_role(user, account) do
    %{ user | role: get_role(user, account) }
  end

  defmodule Query do
    use BlueJet, :query

    def default() do
      from(u in User, order_by: [desc: :inserted_at])
    end

    def global(query) do
      from u in query, where: is_nil(u.account_id)
    end

    def member_of_account(query, account_id) do
      from u in query,
        join: ac in AccountMembership, on: ac.user_id == u.id,
        where: ac.account_id == ^account_id
    end
  end
end
