defmodule BlueJet.ExternalFile do
  use BlueJet.Web, :model

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

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :status, :content_type, :size_bytes, :public_readable, :version_name, :system_tag, :original_id])
    |> validate_required([:name, :content_type, :size_bytes])
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
      "uploaded" -> :get
    end

    {:ok, url} = ExAws.S3.presigned_url(config, method, System.get_env("AWS_S3_BUCKET_NAME"), s3_key, opts)

    url
  end
end
