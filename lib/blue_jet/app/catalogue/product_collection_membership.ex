defmodule BlueJet.Catalogue.ProductCollectionMembership do
  @behaviour BlueJet.Data

  use BlueJet, :data

  alias BlueJet.Catalogue.{Product, ProductCollection}

  schema "product_collection_memberships" do
    field :account_id, UUID
    field :account, :map, virtual: true
    field :sort_index, :integer, default: 1000

    timestamps()

    belongs_to :collection, ProductCollection
    belongs_to :product, Product
  end

  @type t :: Ecto.Schema.t()

  @system_fields [
    :id,
    :account_id,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  @spec changeset(__MODULE__.t(), :insert, map) :: Changeset.t()
  def changeset(membership, action, fields)
  def changeset(membership, :insert, params) do
    membership
    |> cast(params, castable_fields(:insert))
    |> Map.put(:action, :insert)
    |> validate()
  end

  @spec changeset(__MODULE__.t(), :update, map, String.t()) :: Changeset.t()
  def changeset(membership, action, fields, locale \\ nil)
  def changeset(membership, :update, params, _) do
    membership
    |> cast(params, castable_fields(:update))
    |> Map.put(:action, :update)
    |> validate()
  end

  @spec changeset(__MODULE__.t(), :delete) :: Changeset.t()
  def changeset(membership, action)
  def changeset(membership, :delete) do
    change(membership)
    |> Map.put(:action, :delete)
  end

  defp castable_fields(:insert) do
    writable_fields()
  end

  defp castable_fields(:update) do
    writable_fields() -- [:collection_id, :product_id]
  end

  def validate(changeset) do
    changeset
    |> validate_required([:collection_id, :product_id])
    |> unique_constraint(
      :product_id,
      name: :product_collection_memberships_product_id_collection_id_index
    )
    |> validate_collection_id()
    |> validate_product_id()
  end

  defp validate_collection_id(
         changeset = %{valid?: true, changes: %{collection_id: collection_id}}
       ) do
    account_id = get_field(changeset, :account_id)
    collection = Repo.get(ProductCollection, collection_id)

    if collection && collection.account_id == account_id do
      changeset
    else
      add_error(changeset, :collection, "is invalid", code: :invalid)
    end
  end

  defp validate_collection_id(changeset), do: changeset

  defp validate_product_id(changeset = %{valid?: true, changes: %{product_id: product_id}}) do
    account_id = get_field(changeset, :account_id)
    product = Repo.get(Product, product_id)

    if product && product.account_id == account_id do
      changeset
    else
      add_error(changeset, :product, "is invalid", code: :invalid)
    end
  end

  defp validate_product_id(changeset), do: changeset
end
