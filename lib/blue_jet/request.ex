defmodule BlueJet.AccessRequest do
  defstruct vas: %{},

            params: %{},
            fields: %{},

            filter: %{},
            sort: %{},
            pagination: %{},

            preloads: [],
            locale: "en"
end