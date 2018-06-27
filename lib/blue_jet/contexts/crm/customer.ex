defmodule BlueJet.Crm.Customer do
  use BlueJet, :data

  alias BlueJet.Utils

  alias __MODULE__.Proxy
  alias BlueJet.Crm.PointAccount
  alias BlueJet.Crm.IdentityService

  schema "customers" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string, default: "guest"
    field :code, :string
    field :name, :string
    field :label, :string

    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :phone_number, :string

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :stripe_customer_id, :string

    field :user_id, Ecto.UUID
    field :user, :map, virtual: true
    field :username, :string, virtual: true
    field :password, :string, virtual: true

    field :file_collections, {:array, :map}, virtual: true, default: []

    timestamps()

    has_one :point_account, PointAccount
    belongs_to :enroller, __MODULE__
    belongs_to :sponsor, __MODULE__
  end

  @type t :: Ecto.Schema.t()

  @system_fields [
    :id,
    :account_id,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    (__MODULE__.__schema__(:fields) -- @system_fields) ++ [:username, :password]
  end

  def translatable_fields do
    [
      :caption,
      :description,
      :custom_data
    ]
  end

  @spec changeset(__MODULE__.t(), atom, map) :: Changeset.t()
  def changeset(customer, :insert, params) do
    customer
    |> cast(params, writable_fields())
    |> Map.put(:action, :insert)
    |> put_name()
    |> Utils.put_clean_email()
    |> validate()
  end

  @spec changeset(__MODULE__.t(), atom, map, String.t(), String.t()) :: Changeset.t()
  def changeset(customer, :update, params, locale \\ nil, default_locale \\ nil) do
    customer = Proxy.put_account(customer)
    default_locale = default_locale || customer.account.default_locale
    locale = locale || default_locale

    customer
    |> cast(params, writable_fields())
    |> Map.put(:action, :update)
    |> put_name()
    |> Utils.put_clean_email()
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  @spec changeset(__MODULE__.t(), atom) :: Changeset.t()
  def changeset(customer, :delete) do
    change(customer)
    |> Map.put(:action, :delete)
  end

  defp put_name(changeset = %{changes: %{name: _}}), do: changeset

  defp put_name(changeset) do
    first_name = get_field(changeset, :first_name)
    last_name = get_field(changeset, :last_name)

    if first_name && last_name do
      put_change(changeset, :name, "#{first_name} #{last_name}")
    else
      changeset
    end
  end

  @spec validate(Changeset.t()) :: Changeset.t()
  def validate(changeset) do
    changeset
    |> validate_required(required_fields(changeset))
    |> validate_format(:email, Application.get_env(:blue_jet, :email_regex))
    |> foreign_key_constraint(:account_id)
    |> unique_constraint(:email, name: :customers_account_id_status_email_index)
  end

  defp required_fields(changeset) do
    status = get_field(changeset, :status)

    case status do
      "guest" -> [:status]
      "internal" -> [:status]
      "registered" -> [:status, :name, :email]
      "suspended" -> [:status]
    end
  end

  @spec match_by(__MODULE__.t() | nil, list) :: __MODULE__.t() | nil
  def match_by(nil, _), do: nil

  def match_by(customer, matcher) do
    matcher = Map.take(matcher, [:name, :phone_number])
    do_match_by(customer, matcher)
  end

  defp do_match_by(customer, matcher) when map_size(matcher) == 0, do: customer

  defp do_match_by(customer, matcher) do
    leftover =
      Enum.reject(matcher, fn {k, v} ->
        case k do
          :first_name ->
            String.downcase(v) == remove_space(downcase(customer.first_name))

          :last_name ->
            String.downcase(v) == remove_space(downcase(customer.last_name))

          :name ->
            remove_space(String.downcase(v)) == remove_space(downcase(customer.name))

          :phone_number ->
            digit_only(v) == digit_only(customer.phone_number)

          :email ->
            downcase(v) == downcase(customer.email)
        end
      end)

    case length(leftover) do
      0 -> customer
      _ -> nil
    end
  end

  defp downcase(nil) do
    nil
  end

  defp downcase(value) do
    String.downcase(value)
  end

  defp digit_only(nil) do
    nil
  end

  defp digit_only(value) do
    String.replace(value, ~r/[^0-9]/, "")
  end

  defp remove_space(nil) do
    nil
  end

  defp remove_space(value) do
    String.replace(value, " ", "")
  end

  @doc """
  If customer is changing status to `registered` this function will create a user
  and add its ID as `user_id` to the customer's changeset, otherwise does nothing.
  """
  @spec put_user_id(Changeset.t()) :: {:ok | :error, Changeset.t()}
  def put_user_id(%{data: customer, changes: %{status: "registered"} = changes} = changeset) do
    account = Proxy.get_account(customer)
    fields = Map.merge(changes, %{role: "customer"})

    with {:ok, user} <- IdentityService.create_user(fields, %{account: account}) do
      changeset = put_change(changeset, :user_id, user.id)

      {:ok, changeset}
    else
      other -> other
    end
  end

  def put_user_id(changeset), do: {:ok, changeset}

  @spec sync_to_user(Customer.t(), map) :: {:ok, Customer.t()}
  def sync_to_user(customer, opts \\ %{})

  def sync_to_user(%{user_id: nil} = customer, _), do: {:ok, customer}

  def sync_to_user(customer, opts) do
    with {:ok, _} <- Proxy.sync_to_user(customer, opts) do
      {:ok, customer}
    else
      other -> other
    end
  end

  @spec delete_user(Customer.t()) :: {:ok, Customer.t()}
  def delete_user(%{user_id: nil} = customer, _), do: {:ok, customer}

  def delete_user(customer) do
    account = Proxy.get_account(customer)

    with {:ok, _} <- IdentityService.delete_user(customer.user_id, %{account: account}) do
      {:ok, customer}
    else
      other -> other
    end
  end
end
