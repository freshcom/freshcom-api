defmodule BlueJet.ProductItem do
  use BlueJet.Web, :model

  schema "product_items" do
    field :code, :string
    field :status, :string
    field :sort_index, :integer
    field :quantity, :integer
    field :maximum_order_quantity, :integer
    field :primary, :boolean, default: false
    field :print_name, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:code, :status, :sort_index, :quantity, :maximum_order_quantity, :primary, :print_name])
    |> validate_required([:code, :status, :sort_index, :quantity, :maximum_order_quantity, :primary, :print_name])
  end
end
