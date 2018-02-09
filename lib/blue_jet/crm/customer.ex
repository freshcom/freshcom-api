defmodule BlueJet.Crm.Customer do
  use BlueJet, :data

  use Trans, translates: [
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias BlueJet.Utils

  alias BlueJet.Crm.Customer.Proxy
  alias BlueJet.Crm.PointAccount
  alias BlueJet.Crm.{IdentityService, StripeClient}

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

    timestamps()

    has_one :point_account, PointAccount
    belongs_to :enroller, __MODULE__
    belongs_to :sponsor, __MODULE__
  end

  @type t :: Ecto.Schema.t

  @system_fields [
    :id,
    :account_id,
    :stripe_customer_id,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  def translatable_fields do
    __MODULE__.__trans__(:fields)
  end

  def required_fields(changeset) do
    status = get_field(changeset, :status)

    case status do
      "guest" -> [:status, :name]
      "internal" -> [:status, :name]
      "registered" -> [:status, :name, :email]
      "suspended" -> [:status, :name]
    end
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields(changeset))
    |> validate_format(:email, Application.get_env(:blue_jet, :email_regex))
    |> foreign_key_constraint(:account_id)
    |> unique_constraint(:email, name: :customers_account_id_status_email_index)
  end

  def changeset(customer, :insert, params) do
    customer
    |> cast(params, writable_fields())
    |> Map.put(:action, :insert)
    |> put_name()
    |> Utils.put_clean_email()
    |> validate()
  end

  def changeset(customer, :update, params, locale \\ nil, default_locale \\ nil) do
    customer = Proxy.put_account(customer)
    default_locale = default_locale || customer.account.default_locale
    locale = locale || default_locale

    customer
    |> cast(params, writable_fields())
    |> put_name()
    |> Utils.put_clean_email()
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  def changeset(customer, :delete) do
    change(customer)
    |> Map.put(:action, :delete)
  end

  def put_name(changeset = %{ changes: %{ name: _ } }), do: changeset

  def put_name(changeset) do
    first_name = get_field(changeset, :first_name)
    last_name = get_field(changeset, :last_name)

    if first_name && last_name do
      put_change(changeset, :name, "#{first_name} #{last_name}")
    else
      changeset
    end
  end

  def match?(nil, _) do
    false
  end

  def match?(customer, params) do
    params = Map.take(params, ["first_name", "last_name", "name", "phone_number"])
    do_match?(customer, params)
  end

  def do_match?(_, params) when map_size(params) == 0, do: false

  def do_match?(customer, params) do
    params = Map.take(params, ["first_name", "last_name", "name", "phone_number"])

    leftover = Enum.reject(params, fn({k, v}) ->
      case k do
        "first_name" ->
          String.downcase(v) == remove_space(downcase(customer.first_name))
        "last_name" ->
          String.downcase(v) == remove_space(downcase(customer.last_name))
        "name" ->
          remove_space(String.downcase(v)) == remove_space(downcase(customer.name))
        "phone_number" ->
          digit_only(v) == digit_only(customer.phone_number)
        "email" ->
          downcase(v) == downcase(customer.email)
      end
    end)

    case length(leftover) do
      0 -> true
      _ -> false
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

  def preprocess(fields, changeset = %{ data: customer, changes: %{ status: "registered" } }) do
    account = Proxy.get_account(customer)
    fields = Map.merge(fields, %{ "role" => "customer" })

    with {:ok, user} <- IdentityService.create_user(fields, %{ account: account }) do
      customer = %{ customer | user_id: user.id }
      changeset = %{ changeset | data: customer }
      {:ok, changeset}
    else
      other -> other
    end
  end

  def preprocess(_, changeset), do: {:ok, changeset}

  def process(customer, %{ action: :insert }) do
    Repo.insert(%PointAccount{
      account_id: customer.account_id,
      customer_id: customer.id
    })

    {:ok, customer}
  end

  def process(customer = %{ user_id: user_id }, %{ action: :delete }) when not is_nil(user_id) do
    account = Proxy.get_account(customer)
    with {:ok, _} <- IdentityService.delete_user(user_id, %{ account: account }) do
      {:ok, customer}
    else
      other -> other
    end
  end

  def process(customer, _), do: {:ok, customer}

  ######
  # External Resources
  #####
  use BlueJet.FileStorage.Macro,
    put_external_resources: :file_collection,
    field: :file_collections,
    owner_type: "Customer"

  def put_external_resources(customer, _, _), do: customer


  @doc """
  Preprocess the customer to be ready for its first payment
  """
  @spec ensure_stripe_customer(__MODULE__.t, Keyword.t) :: __MODULE__.t
  def ensure_stripe_customer(customer = %__MODULE__{ stripe_customer_id: stripe_customer_id }, payment_processor: "stripe") when is_nil(stripe_customer_id) do
    customer = Proxy.put_account(customer)
    {:ok, stripe_customer} = create_stripe_customer(customer)

    customer
    |> change(stripe_customer_id: stripe_customer["id"])
    |> Repo.update!()
  end

  def ensure_stripe_customer(customer, _), do: customer

  # @spec get_stripe_card_by_fingerprint(Customer.t, String.t) :: map | nil
  # defp get_stripe_card_by_fingerprint(customer = %Customer{ stripe_customer_id: stripe_customer_id }, target_fingerprint) when not is_nil(stripe_customer_id) do
  #   customer = %{ customer | account: get_account(customer) }
  #   with {:ok, %{ "data" => cards }} <- list_stripe_card(customer) do
  #     Enum.find(cards, fn(card) -> card["fingerprint"] == target_fingerprint end)
  #   else
  #     other -> other
  #   end
  # end

  @spec create_stripe_customer(__MODULE__.t) :: {:ok, map} | {:error, map}
  defp create_stripe_customer(customer) do
    account = Proxy.get_account(customer)
    StripeClient.post("/customers", %{ email: customer.email, metadata: %{ fc_customer_id: customer.id } }, mode: account.mode)
  end

  # @spec list_stripe_card(Customer.t) :: {:ok, map} | {:error, map}
  # defp list_stripe_card(customer = %Customer{ stripe_customer_id: stripe_customer_id }) when not is_nil(stripe_customer_id) do
  #   account = get_account(customer)
  #   StripeClient.get("/customers/#{stripe_customer_id}/sources?object=card&limit=100", mode: account.mode)
  # end
end
