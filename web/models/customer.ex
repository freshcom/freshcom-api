defmodule BlueJet.Customer do
  use BlueJet.Web, :model

  schema "customers" do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :encrypted_password, :string
    field :display_name, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:first_name, :last_name, :email, :encrypted_password, :display_name])
    |> validate_required([:first_name, :last_name, :email, :encrypted_password, :display_name])
  end
end
