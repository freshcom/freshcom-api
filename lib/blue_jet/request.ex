defmodule BlueJet.AccessRequest do
  defstruct vas: %{},
            role: nil,

            params: %{},
            fields: %{},

            search: "",
            filter: %{},
            sort: %{},
            pagination: %{},

            preloads: [],
            locale: "en"
end