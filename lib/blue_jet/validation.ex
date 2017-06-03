defmodule BlueJet.Validation do
  def validate_required_exactly_one(changeset, fields) do
    values = Enum.reduce(fields, [], fn(field, acc) ->
      with {_, value} <- Ecto.Changeset.fetch_field(changeset, field) do
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
        Ecto.Changeset.add_error(changeset, :fields, "Exactly one of #{fields_str} must not be nil")
    end
  end
end