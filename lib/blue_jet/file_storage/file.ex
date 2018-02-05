defmodule BlueJet.FileStorage.File do
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias BlueJet.FileStorage.FileCollectionMembership
  alias BlueJet.FileStorage.File.Proxy

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

  def changeset(ef, :update, params, locale \\ nil, default_locale \\ nil) do
    ef = %{ ef | account: Proxy.get_account(ef) }
    default_locale = default_locale || ef.account.default_locale
    locale = locale || default_locale

    ef
    |> cast(params, writable_fields())
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  def key(struct) do
    prefix = Application.get_env(:blue_jet, :s3)[:prefix]
    id = struct.id
    name = struct.name

    "#{prefix}/File/#{id}/#{name}"
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
end
