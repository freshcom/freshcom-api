defmodule BlueJet.Sku do
  use BlueJet.Web, :model

  schema "skus" do
    field :number, :string
    field :status, :string
    field :name, :string
    field :print_name, :string
    field :unit_of_measure, :string
    field :variable_weight, :boolean
    field :stackable, :boolean

    field :storage_type, :string
    field :storage_size, :integer

    field :caption, :string
    field :description, :string
    field :specification, :string
    field :storage_description, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:number, :status, :name, :print_name, :unit_of_measure,
                     :variable_weight, :stackable, :storage_type, :storage_size,
                     :caption, :description, :specification])
    |> validate_required([:status, :name, :print_name])
  end
end
