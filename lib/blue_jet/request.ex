defmodule BlueJet.AccessRequest do
  defstruct vas: %{},
            role: nil,

            params: %{},
            fields: %{},

            search: "",
            filter: %{},
            sort: %{},
            pagination: %{},
            counts: %{ all: %{} },

            account: nil,

            preloads: [],
            locale: nil
end