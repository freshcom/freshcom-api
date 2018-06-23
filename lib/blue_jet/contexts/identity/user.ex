defmodule BlueJet.Identity.User do
  use BlueJet, :data

  alias BlueJet.Utils

  alias BlueJet.Identity.{Account, RefreshToken, AccountMembership, PhoneVerificationCode}
  alias __MODULE__.Query

  schema "users" do
    field :status, :string, default: "active"

    field :username, :string
    field :email, :string
    field :phone_number, :string
    field :encrypted_password, :string
    field :name, :string
    field :first_name, :string
    field :last_name, :string

    field :auth_method, :string, default: "simple" # tfa_email, tfa_sms
    field :tfa_code, :string
    field :tfa_code_expires_at, :utc_datetime

    field :email_verification_token, :string
    field :email_verified, :boolean, default: false
    field :email_verified_at, :utc_datetime

    field :password_reset_token, :string
    field :password_reset_token_expires_at, :utc_datetime
    field :password_updated_at, :utc_datetime

    field :phone_verification_code, :string, virtual: true
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

    :tfa_code,
    :tfa_code_expires_at,

    :email_verification_token,
    :email_verified,
    :email_verified_at,

    :password_reset_token,
    :password_reset_token_expires_at,
    :password_updated_at,

    :inserted_at,
    :updated_at
  ]

  @required_fields [
    :username
  ]

  def writable_fields do
    (__MODULE__.__schema__(:fields) -- @system_fields()) ++ [:password, :current_password, :phone_verification_code]
  end

  @spec changeset(__MODULE__.t, atom, map, map) :: Changeset.t()
  def changeset(user, action, params, opts \\ %{})

  def changeset(user, :insert, params, opts) do
    user
    |> Repo.preload(:account)
    |> cast(params, writable_fields())
    |> Map.put(:action, :insert)
    |> put_name()
    |> Utils.put_parameterized([:email, :username])
    |> put_auth_method()
    |> put_tfa_code()
    |> put_email_fields()
    |> put_encrypted_password()
    |> validate(%{ bypass_pvc: !!opts[:bypass_pvc_validation] })
  end

  def changeset(user, :update, params, opts) do
    user
    |> Repo.preload(:account)
    |> cast(params, writable_fields())
    |> Map.put(:action, :update)
    |> put_name()
    |> Utils.put_parameterized([:email, :username])
    |> put_email_fields()
    |> put_encrypted_password()
    |> validate(%{ bypass_pvc: !!opts[:bypass_pvc_validation] })
  end

  @spec changeset(__MODULE__.t, atom) :: Changeset.t()
  def changeset(user, :delete) do
    change(user)
    |> Map.put(:action, :delete)
  end

  @spec encrypt_password(String.t()) :: Changeset.t()
  def encrypt_password(password) do
    Comeonin.Bcrypt.hashpwsalt(password)
  end

  @spec put_encrypted_password(Changeset.t()) :: Changeset.t()
  def put_encrypted_password(changeset = %{ changes: %{ password: password } })  do
    put_change(changeset, :encrypted_password, encrypt_password(password))
  end

  def put_encrypted_password(changeset), do: changeset

  defp put_name(changeset = %{ changes: %{ name: _ } }), do: changeset

  defp put_name(changeset) do
    first_name = get_field(changeset, :first_name)
    last_name = get_field(changeset, :last_name)

    if first_name && last_name do
      put_change(changeset, :name, "#{first_name} #{last_name}")
    else
      changeset
    end
  end

  defp put_auth_method(changeset = %{ changes: %{ auth_method: _ } }), do: changeset

  defp put_auth_method(changeset = %{ data: %{ account: %{ default_auth_method: default_auth_method } } }) do
    put_change(changeset, :auth_method, default_auth_method)
  end

  defp put_auth_method(changeset), do: changeset

  defp put_tfa_code(changeset = %{ action: :insert }) do
    pvc = get_field(changeset, :phone_verification_code)
    changeset
    |> put_change(:tfa_code, pvc)
    |> put_change(:tfa_code_expires_at, Timex.shift(Timex.now(), minutes: 5))
  end

  defp put_email_fields(changeset = %{ changes: %{ email: _ } }) do
    changeset
    |> put_change(:email_verified, false)
    |> put_change(:email_verification_token, generate_email_verification_token())
  end

  defp put_email_fields(changeset), do: changeset

  defp validate(changeset, opts \\ %{})

  defp validate(changeset = %{ action: :insert }, opts) do
    changeset
    |> validate_required(@required_fields)

    |> validate_username()
    |> validate_email()

    |> validate_phone_number()
    |> validate_phone_verification_code(%{ bypass: !!opts[:bypass_pvc] })

    |> validate_password()
  end

  defp validate(changeset = %{ action: :update }, opts) do
    changeset
    |> validate_required(@required_fields)

    |> validate_username()
    |> validate_email()

    |> validate_phone_number()
    |> validate_phone_verification_code(%{ bypass: !!opts[:bypass_pvc] })

    |> validate_current_password()
    |> validate_password()
  end

  # This function is needed in additional to the constraint. The constraints
  # only checks account user and global user seperately. In addition to that
  # we also need to check them together. Username must be unique within an
  # account regardless of whether they are global user or account user.
  defp validate_username_unique_within_account(changeset = %{ valid?: true, changes: %{ username: username } }) do
    account_id = get_field(changeset, :account_id)

    if username_unique_within_account?(username, account_id) do
      changeset
    else
      add_error(changeset, :username, "Username already taken.", [validation: :unique])
    end
  end

  defp validate_username_unique_within_account(changeset), do: changeset

  defp username_unique_within_account?(_, nil), do: true

  defp username_unique_within_account?(username, account_id) do
    existing_user =
      Query.default()
      |> Query.member_of_account(account_id)
      |> Repo.get_by(username: username)

    !existing_user
  end

  defp validate_username(changeset = %{ valid?: true, changes: %{ username: _ } }) do
    changeset
    |> validate_length(:username, min: 5)
    |> validate_username_unique_within_account()
    |> unique_constraint(:username)
    |> unique_constraint(:username, name: :users_account_id_username_index)
  end

  defp validate_username(changeset), do: changeset

  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, Application.get_env(:blue_jet, :email_regex))
    |> unique_constraint(:email)
  end

  defp validate_current_password(changeset = %{ data: user, changes: %{ password: _ } }) do
    current_password = get_field(changeset, :current_password)
    changeset = validate_required(changeset, [:current_password])

    if current_password && !checkpw(current_password, user.encrypted_password) do
      add_error(changeset, :current_password, "is invalid", validation: :must_match)
    else
      changeset
    end
  end

  defp validate_current_password(changeset), do: changeset

  defp validate_phone_number(changeset) do
    auth_method = get_field(changeset, :auth_method)

    if auth_method == "tfa_sms" do
      changeset
      |> validate_required([:phone_number])
      |> validate_format(:phone_number, Application.get_env(:blue_jet, :phone_regex))
    else
      changeset
    end
  end

  defp validate_phone_verification_code_exists(changeset = %{ valid?: true }) do
    pvc = get_field(changeset, :phone_verification_code)
    phone_number = get_field(changeset, :phone_number)

    if PhoneVerificationCode.exists?(pvc, phone_number) do
      changeset
    else
      add_error(changeset, :phone_verification_code, "is invalid.", code: :invalid)
    end
  end

  defp validate_phone_verification_code_exists(changeset), do: changeset

  defp validate_phone_verification_code(changeset, %{ bypass: true }), do: changeset

  defp validate_phone_verification_code(changeset = %{ action: action }, _) do
    auth_method = get_field(changeset, :auth_method)
    is_updating_phone_number = action == :update && get_change(changeset, :phone_number)

    if (action == :insert || is_updating_phone_number) && auth_method == "tfa_sms" do
      changeset
      |> validate_required([:phone_verification_code])
      |> validate_phone_verification_code_exists()
    else
      changeset
    end
  end

  defp validate_password(changeset = %{ action: :insert }) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8)
  end

  defp validate_password(changeset = %{ action: :update, changes: %{ password: _ } }) do
    changeset
    |> validate_length(:password, min: 8)
  end

  defp validate_password(changeset), do: changeset

  defp checkpw(nil, _), do: false
  defp checkpw(_, nil), do: false
  defp checkpw(pp, ep), do: Comeonin.Bcrypt.checkpw(pp, ep)

  @spec delete_all_pvc(__MODULE__.t) :: {:ok, __MODULE__.t}
  def delete_all_pvc(%{ phone_verification_code: nil } = user), do: {:ok, user}

  def delete_all_pvc(user) do
    PhoneVerificationCode.Query.default()
    |> PhoneVerificationCode.Query.filter_by(%{ phone_number: user.phone_number })
    |> Repo.delete_all()

    {:ok, user}
  end

  @spec put_role(__MODULE__.t | nil, String.t()) :: __MODULE__.t | nil
  def put_role(nil, _), do: nil

  def put_role(user, account_id) do
    %{ user | role: get_role(user, account_id) }
  end

  @spec get_tfa_code(__MODULE__.t) :: String.t()
  def get_tfa_code(user) do
    if user.tfa_code && Timex.before?(Timex.now, user.tfa_code_expires_at) do
      user.tfa_code
    else
      nil
    end
  end

  @spec get_role(__MODULE__.t, String.t()) :: String.t()
  def get_role(user, account_id) do
    membership = Repo.get_by(AccountMembership, user_id: user.id, account_id: account_id)

    if membership do
      membership.role
    else
      nil
    end
  end

  @spec verify_email(__MODULE__.t) :: __MODULE__.t
  def verify_email(user) do
    user
    |> change(email_verification_token: nil, email_verified: true, email_verified_at: Ecto.DateTime.utc())
    |> Repo.update!()
  end

  @spec generate_email_verification_token() :: String.t
  def generate_email_verification_token() do
    Ecto.UUID.generate()
  end

  @spec refresh_email_verification_token(__MODULE__.t) :: __MODULE__.t
  def refresh_email_verification_token(user) do
    user
    |> change(email_verification_token: generate_email_verification_token(), email_verified: false)
    |> Repo.update!()
  end

  @spec refresh_tfa_code(__MODULE__.t) :: __MODULE__.t
  def refresh_tfa_code(user) do
    user
    |> change(%{ tfa_code: generate_tfa_code(6), tfa_code_expires_at: Timex.shift(Timex.now(), minutes: 5) })
    |> Repo.update!()
  end

  defp generate_tfa_code(n) do
    Enum.reduce(1..n, "", fn(_, acc) ->
      char = Enum.random(0..9)
      acc <> Integer.to_string(char)
    end)
  end

  @spec clear_tfa_code(__MODULE__.t) :: __MODULE__.t
  def clear_tfa_code(user) do
    user
    |> change(%{ tfa_code: nil, tfa_code_expires_at: nil })
    |> Repo.update!()
  end

  @spec refresh_password_reset_token(__MODULE__.t) :: __MODULE__.t
  def refresh_password_reset_token(user) do
    user
    |> change(password_reset_token: Ecto.UUID.generate())
    |> Repo.update!()
  end

  @spec update_password(__MODULE__.t, String.t()) :: __MODULE__.t
  def update_password(user, new_password) do
    user
    |> change(encrypted_password: Comeonin.Bcrypt.hashpwsalt(new_password))
    |> Repo.update!()
  end
end
