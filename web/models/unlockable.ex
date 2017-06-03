defmodule BlueJet.Unlockable do
  use BlueJet.Web, :model

  schema "unlockables" do
    field :code, :string
    field :status, :string
    field :name, :string
    field :print_name, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:code, :status, :name, :print_name])
    |> validate_required([:code, :status, :name, :print_name])
  end
end
