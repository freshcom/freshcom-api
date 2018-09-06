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
            pagination: %{ size: 25, number: 1 },

            preloads: [],
            preload_filters: %{},
            locale: nil

  @type t :: map
end