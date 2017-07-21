defmodule BlueJet.ExternalFile do
  use BlueJet.Web, :model

  alias BlueJet.Validation

  schema "external_files" do
    field :status, :string, default: "pending"
    field :name, :string
    field :content_type, :string
    field :size_bytes, :integer
    field :public_readable, :boolean, default: false
    field :version_name, :string
    field :system_tag, :string
    field :original_id, Ecto.UUID
    field :url, :string, virtual: true

    field :custom_data, :map, default: %{}

    timestamps()

    belongs_to :account, BlueJet.Account
    belongs_to :user, BlueJet.User
    belongs_to :customer, BlueJet.Customer
  end

  def fields do
    BlueJet.ExternalFile.__schema__(:fields)
    -- [:id, :translations, :inserted_at, :updated_at]
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    fields() -- [:account_id, :user_id, :customer_id]
  end

  def required_fields do
    [:account_id, :status, :name, :content_type, :size_bytes]
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields())
    |> Validation.validate_required_exactly_one([:user_id, :customer_id], :relationships)
    |> foreign_key_constraint(:account_id)
    |> foreign_key_constraint(:user_id)
    |> validate_assoc_account_scope(:customer)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, castable_fields(struct))
    |> validate()
  end

  def key(struct) do
    prefix = Application.get_env(:blue_jet, :s3)[:prefix]
    id = struct.id
    name = struct.name

    "#{prefix}/ExternalFile/#{id}/#{name}"
  end

  def put_url(struct, opts \\ []) do
    %{ struct | url: url(struct, opts) }
  end

  def url(struct, opts \\ []) do
    s3_key = key(struct)
    config = ExAws.Config.new(:s3)

    method = case struct.status do
      "pending" -> :put
      _ -> :get
    end

    {:ok, url} = ExAws.S3.presigned_url(config, method, System.get_env("AWS_S3_BUCKET_NAME"), s3_key, opts)

    url
  end

  def delete_object(struct) do
    ExAws.S3.delete_object(System.get_env("AWS_S3_BUCKET_NAME"), key(struct))

    struct
  end
end
