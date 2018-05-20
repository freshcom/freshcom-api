defmodule BlueJet.Validation do

  alias Ecto.Changeset
  alias BlueJet.Repo

  def validate_required_exactly_one(changeset, fields, error_key \\ :fields) do
    values = Enum.reduce(fields, [], fn(field, acc) ->
      with {_, value} <- Changeset.fetch_field(changeset, field) do
        [value | acc]
      else
        :error -> [nil | acc]
      end
    end)

    nil_count = Enum.count(values, fn(value) ->
      value == nil
    end)

    case nil_count do
      1 -> changeset
      _ ->
        fields_str = Enum.join(fields, ", ")
        Changeset.add_error(changeset, error_key, "Exactly one of #{fields_str} must not be nil")
    end
  end

  def validate_assoc_account_scope(changeset, assocs) when is_list(assocs) do
    Enum.reduce(assocs, changeset, fn(assoc, changeset) ->
      validate_assoc_account_scope(changeset, assoc)
    end)
  end
  def validate_assoc_account_scope(changeset, assoc) when is_atom(assoc) do
    assoc_reflection = changeset.data.__struct__.__schema__(:association, assoc)
    queryable = assoc_reflection.queryable
    owner_key = assoc_reflection.owner_key
    account_id = Changeset.get_field(changeset, :account_id)

    with {:ok, assoc_id} <- Changeset.fetch_change(changeset, owner_key),
         true <- !!Repo.get_by(queryable, account_id: account_id, id: assoc_id)
    do
      changeset
    else
      :error -> changeset
      false -> Changeset.add_error(changeset, owner_key, "doesn't exist")
    end
  end
end