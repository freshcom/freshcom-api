defmodule BlueJet.ContextRequest do
  defstruct vas: %{},
            account: nil,
            user: nil,
            role: nil,

            params: %{},
            fields: %{},

            search: "",
            filter: %{},
            sort: %{},
            pagination: %{size: 25, number: 1},

            preloads: [],
            preload_filters: %{},
            locale: nil

  @type t :: map

  def put(req, root_key, key, value) do
    root_value =
      req
      |> Map.get(root_key)
      |> Map.put(key, value)

    Map.put(req, root_key, root_value)
  end
end