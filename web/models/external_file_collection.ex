defmodule BlueJet.ExternalFileCollection do
  use BlueJet.Web, :model

  schema "external_file_collections" do
    field :name, :string
    field :label, :string
    field :external_file_ids, {:array, :binary}
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
