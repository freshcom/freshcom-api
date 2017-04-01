defmodule BlueJet.S3FileSet do
  use BlueJet.Web, :model

  schema "s3_file_sets" do
    field :name, :string
    field :label, :string
    field :s3_file_ids, {:array, :binary}
    field :translations, :map

    timestamps()

    belongs_to :sku, BlueJet.Sku
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :label])
    |> validate_required([:label])
  end
end
