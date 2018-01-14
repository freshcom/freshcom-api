defmodule BlueJet.Identity.User do
  use BlueJet, :data

  alias BlueJet.Repo

  alias BlueJet.Identity.Account
  alias BlueJet.Identity.RefreshToken
  alias BlueJet.Identity.AccountMembership

  schema "users" do
    field :status, :string, default: "active"

    field :username, :string
    field :email, :string
    field :encrypted_password, :string
    field :name, :string
    field :first_name, :string
    field :last_name, :string

    field :email_confirmation_token, :string
    field :email_confirmed, :boolean, default: false
    field :email_confirmed_at, :utc_datetime

    field :password_reset_token, :string
    field :password_reset_token_expires_at, :utc_datetime
    field :password_updated_at, :utc_datetime

    field :password, :string, virtual: true
    field :current_password, :string, virtual: true

    timestamps()

    field :role, :string, virtual: true

    belongs_to :default_account, Account
    belongs_to :account, Account
    has_many :refresh_tokens, RefreshToken
    has_many :account_memberships, AccountMembership
  end

  @type t :: Ecto.Schema.t

  @system_fields [
    :id,
    :default_account_id,
    :account_id,
    :encrypted_password,

    :email_confirmation_token,
    :email_confirmed,
    :email_confirmed_at,

    :password_reset_token,
    :password_reset_token_expires_at,
    :password_updated_at,

    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    (__MODULE__.__schema__(:fields) -- @system_fields()) ++ [:password, :current_password]
  end

  defp required_fields, do: [:username]

  defp required_fields(%{ data: %{ __meta__: %{ state: :built } } }), do: required_fields() ++ [:password]

  # If changing password, current password is required
  defp required_fields(%{ data: %{ __meta__: %{ state: :loaded } }, changes: %{ password: _ } }) do
    required_fields() ++ [:current_password]
  end

  defp required_fields(%{ data: %{ __meta__: %{ state: :loaded } } }), do: required_fields()

  defp username_valid?(username, nil), do: true

  defp username_valid?(username, account_id) do
    existing_user =
      __MODULE__.Query.default()
      |> __MODULE__.Query.member_of_account(account_id)
      |> Repo.get_by(username: username)

    !existing_user
  end

  defp validate_username(changeset = %{ valid?: true, changes: %{ username: username } }) do
    account_id = get_field(changeset, :account_id)

    if username_valid?(username, account_id) do
      changeset
    else
      add_error(changeset, :username, "Username already taken.", [validation: :unique])
    end
  end

  defp validate_username(changeset), do: changeset

  defp validate_current_password(changeset = %{
    valid?: true,
    data: %{ __meta__: %{ state: :loaded } },
    changes: %{ password: _ }
  }) do
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

  def validate(changeset) do
    required_fields = required_fields(changeset)

    changeset
    |> validate_required(required_fields)
    |> validate_length(:username, min: 5)
    |> validate_username()
    |> unique_constraint(:username)
    |> unique_constraint(:username, name: :users_account_id_username_index)

    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
    |> unique_constraint(:email)

    |> validate_current_password()
    |> validate_length(:password, min: 8)

    |> foreign_key_constraint(:default_account_id)
    |> foreign_key_constraint(:account_id)
  end

  defp put_encrypted_password(changeset = %{ valid?: true, changes: %{ password: password } })  do
    put_change(changeset, :encrypted_password, Comeonin.Bcrypt.hashpwsalt(password))
  end

  defp put_encrypted_password(changeset), do: changeset

  def changeset(struct, params) do
    struct
    |> cast(params, writable_fields())
    |> validate()
    |> put_encrypted_password()
  end

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

  def refresh_password_reset_token(user) do
    user
    |> change(password_reset_token: Ecto.UUID.generate())
    |> Repo.update!()
  end

  defmodule Query do
    use BlueJet, :query

    alias BlueJet.Identity.User

    def default() do
      from(u in User, order_by: [desc: :inserted_at])
    end

    def global(query) do
      from u in query, where: is_nil(u.account_id)
    end

    def for_account(query, account_id) do
      from(u in query, where: u.account_id == ^account_id)
    end

    def member_of_account(query, account_id) do
      from u in query,
        join: ac in AccountMembership, on: ac.user_id == u.id,
        where: ac.account_id == ^account_id
    end
  end
end
