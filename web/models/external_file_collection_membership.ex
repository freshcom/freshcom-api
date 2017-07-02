defmodule BlueJet.ExternalFileCollectionMembership do
  use BlueJet.Web, :model

  alias BlueJet.ExternalFileCollection
  alias BlueJet.ExternalFile
  alias BlueJet.Repo
  alias Ecto.Changeset

  schema "external_file_collection_memberships" do
    field :sort_index, :integer, default: 100

    timestamps()

    belongs_to :account, BlueJet.Account
    belongs_to :collection, BlueJet.ExternalFileCollection
    belongs_to :file, BlueJet.ExternalFile
  end

  def translatable_fields do
    BlueJet.Sku.__trans__(:fields)
  end

  def castable_fields(state) do
    all = [:account_id, :sort_index, :collection_id, :file_id]

    case state do
      :built -> all
      :loaded -> all -- [:account_id, :collection_id, :file_id]
    end
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct = %{ __meta__: %{ state: state } }, params \\ %{}) do
    struct
    |> cast(params, castable_fields(state))
    |> validate_required([:account_id, :collection_id, :file_id])
    |> validate_collection_id
    |> validate_file_id
  end

  defp validate_collection_id(changeset = %Changeset{ changes: %{ collection_id: collection_id } }) do
    {_, account_id} = Changeset.fetch_field(changeset, :account_id)
    case Repo.get_by(ExternalFileCollection, account_id: account_id, id: collection_id) do
      nil -> Changeset.add_error(changeset, :collection_id, "doesn't exist")
      _ -> changeset
    end
  end
  defp validate_collection_id(changeset), do: changeset

  defp validate_file_id(changeset = %Changeset{ changes: %{ file_id: file_id } }) do
    {_, account_id} = Changeset.fetch_field(changeset, :account_id)
    case Repo.get_by(ExternalFile, account_id: account_id, id: file_id) do
      nil -> Changeset.add_error(changeset, :file_id, "doesn't exist")
      _ -> changeset
    end
  end
  defp validate_file_id(changeset), do: changeset

end
