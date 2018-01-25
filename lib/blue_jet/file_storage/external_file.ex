defmodule BlueJet.FileStorage.ExternalFile do
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias BlueJet.FileStorage.ExternalFileCollectionMembership
  alias BlueJet.FileStorage.IdentityService

  schema "external_files" do
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

    has_many :collection_memberships, ExternalFileCollectionMembership, foreign_key: :file_id
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
  def changeset(ef, params, locale \\ nil, default_locale \\ nil) do
    ef = %{ ef | account: get_account(ef) }
    default_locale = default_locale || ef.account.default_locale
    locale = locale || default_locale

    ef
    |> cast(params, writable_fields())
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  def get_account(ef) do
    ef.account || IdentityService.get_account(ef)
  end

  def key(struct) do
    prefix = Application.get_env(:blue_jet, :s3)[:prefix]
    id = struct.id
    name = struct.name

    "#{prefix}/ExternalFile/#{id}/#{name}"
  end

  def put_url(structs, opts \\ [])
  def put_url(structs, opts) when is_list(structs) do
    Enum.map(structs, fn(ef) ->
      put_url(ef, opts)
    end)
  end
  def put_url(struct = %__MODULE__{}, opts), do: %{ struct | url: url(struct, opts) }
  def put_url(struct, _), do: struct

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

    alias BlueJet.FileStorage.ExternalFile

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
