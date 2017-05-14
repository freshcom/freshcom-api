defmodule BlueJet.ExternalFileCollection do
  use BlueJet.Web, :model

  alias BlueJet.Account

  schema "external_file_collections" do
    field :name, :string
    field :label, :string
    field :file_ids, {:array, Ecto.UUID}
    field :translations, :map

    timestamps()

    belongs_to :sku, BlueJet.Sku
    belongs_to :account, Account

    has_many :files, BlueJet.ExternalFile
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :label, :file_ids, :sku_id])
    |> validate_required([:label])
  end

  def put_files(struct) do
    file_ids = struct.file_ids
    files = from(ef in BlueJet.ExternalFile, where: ef.id in ^file_ids) |> BlueJet.Repo.all
    %{ struct | files: files }
  end
end
