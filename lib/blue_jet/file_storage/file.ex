defmodule BlueJet.FileStorage.File do
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias BlueJet.FileStorage.S3Client
  alias BlueJet.FileStorage.CloudfrontClient
  alias BlueJet.FileStorage.FileCollectionMembership
  alias __MODULE__.Proxy

  schema "files" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

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

    has_many :collection_memberships, FileCollectionMembership, foreign_key: :file_id
  end

  @type t :: Ecto.Schema.t

  @system_fields [
    :id,
    :user_id,
    :account_id,
    :system_tag,
    :original_id,
    :translations,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  def translatable_fields do
    __MODULE__.__trans__(:fields)
  end

  defp required_fields do
    [:status, :name, :content_type, :size_bytes]
  end

  def validate(changeset) do
    changeset
    |> validate_required(required_fields())
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(file, :insert, params) do
    file
    |> cast(params, writable_fields())
    |> Map.put(:action, :insert)
    |> validate()
  end

  def changeset(file, :update, params, locale \\ nil, default_locale \\ nil) do
    file = %{ file | account: Proxy.get_account(file) }
    default_locale = default_locale || file.account.default_locale
    locale = locale || default_locale

    file
    |> cast(params, writable_fields())
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  def changeset(file, :delete) do
    change(file)
    |> Map.put(:action, :delete)
  end

  def delete_s3_object(files) when is_list(files) do
    Proxy.delete_s3_object(files)

    :ok
  end

  def process(file, %{ action: :delete }) do
    Proxy.delete_s3_object(file)

    {:ok, file}
  end

  def get_s3_key(files) when is_list(files) do
    Enum.map(files, fn(file) ->
      get_s3_key(file)
    end)
  end

  def get_s3_key(file) do
    prefix = Application.get_env(:blue_jet, :s3)[:prefix]
    id = file.id
    name = file.name
    ext = Path.extname(name)
    "#{prefix}/file/#{id}#{ext}"
  end

  def put_url(structs) when is_list(structs) do
    Enum.map(structs, fn(ef) ->
      put_url(ef)
    end)
  end
  def put_url(struct = %__MODULE__{}), do: %{ struct | url: get_url(struct) }
  def put_url(struct), do: struct

  def get_url(file = %{ status: "pending" }) do
    get_s3_key(file)
    |> S3Client.get_presigned_url(:put)
  end

  def get_url(file) do
    is_cdn_enabled = System.get_env("CDN_ROOT_URL") && String.length(System.get_env("CDN_ROOT_URL")) > 0
    key = get_s3_key(file)

    if is_cdn_enabled do
      CloudfrontClient.get_presigned_url(key)
    else
      S3Client.get_presigned_url(key, :get)
    end
  end
end
