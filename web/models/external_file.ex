defmodule BlueJet.ExternalFile do
  use BlueJet.Web, :model

  alias BlueJet.Validation

  schema "external_files" do
    field :name, :string
    field :status, :string, default: "pending"
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

  def castable_fields(state) do
    all = [:account_id, :name, :status, :content_type, :size_bytes, :public_readable,
      :version_name, :system_tag, :original_id, :user_id, :customer_id]

    case state do
      :built -> all
      :loaded -> all -- [:account_id, :user_id, :customer_id]
    end
  end

  def required_fields do
    [:account_id, :name, :status, :content_type, :size_bytes]
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct = %{ __meta__: %{ state: state } }, params \\ %{}) do
    struct
    |> cast(params, castable_fields(state))
    |> validate_required(required_fields())
    |> Validation.validate_required_exactly_one([:user_id, :customer_id], :relationships)
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
