defmodule BlueJet.ContextResponse do
  defstruct meta: %{}, data: %{}, errors: []

  def put_meta(response, key, value) do
    new_meta = Map.put(response.meta, key, value)
    Map.put(response, :meta, new_meta)
  end
end