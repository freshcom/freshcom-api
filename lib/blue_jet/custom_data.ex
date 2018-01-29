defmodule BlueJet.CustomData do
  @moduledoc """
  This module is deperecated
  """
  def put_change(changeset, params, system_fields) do
    custom_fields = Map.keys(params) -- system_fields
    custom_data = Map.take(params, custom_fields)
    case length(Map.keys(custom_data)) do
      0 -> changeset
      _ -> Ecto.Changeset.put_change(changeset, :custom_data, custom_data)
    end
  end

  def deserialize(%{ custom_data: custom_data } = struct) do
    custom_fields = Map.new(custom_data, fn({k, v}) -> { String.to_atom(k), v } end)
    Map.merge(struct, custom_fields)
  end

  def deserialize(struct), do: struct
end