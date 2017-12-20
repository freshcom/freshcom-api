defmodule BlueJet.FileStorage.ExternalFile do
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias BlueJet.FileStorage.ExternalFile
  alias BlueJet.FileStorage.ExternalFileCollectionMembership

  schema "external_files" do
    field :account_id, Ecto.UUID
    field :status, :string, default: "pending"
    field :code, :string
    field :name, :string
    field :label, :string

    field :content_type, :string
    field :size_bytes, :integer
    field :public_readable, :boolean, default: false

    field :version_name, :string
    field :version_label, :string
    field :system_tag, :string
    field :original_id, Ecto.UUID

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, defualt: %{}

    field :user_id, Ecto.UUID

    timestamps()

    field :url, :string, virtual: true

    has_many :collection_memberships, ExternalFileCollectionMembership, foreign_key: :file_id
  end

  def system_fields do
    [
      :id,
      :system_tag,
      :inserted_at,
      :updated_at
    ]
  end

  def writable_fields do
    ExternalFile.__schema__(:fields) -- system_fields()
  end

  def translatable_fields do
    ExternalFile.__trans__(:fields)
  end

  def castable_fields(%{ __meta__: %{ state: :built }}) do
    writable_fields()
  end
  def castable_fields(%{ __meta__: %{ state: :loaded }}) do
    writable_fields() -- [:account_id, :user_id, :customer_id]
  end

  def required_fields do
    [:account_id, :status, :name, :content_type, :size_bytes, :user_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields())
    |> foreign_key_constraint(:account_id)
    |> foreign_key_constraint(:user_id)
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

  defmodule Query do
    use BlueJet, :query

    def default() do
      from(ef in ExternalFile, order_by: [desc: ef.updated_at])
    end

    def for_account(query, account_id) do
      from(ef in query, where: ef.account_id == ^account_id)
    end

    def uploaded(query) do
      from(ef in query, where: ef.status == "uploaded")
    end
  end
end
