defmodule BlueJet.Product do
  use BlueJet.Web, :model

  schema "products" do
    field :number, :string
    field :name, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:number, :name])
    |> validate_required([:number, :name])
  end
end
