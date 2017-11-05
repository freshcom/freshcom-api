defmodule BlueJet.AccessRequest do
  defstruct vas: %{},
            params: %{},
            fields: %{},
            filter: %{},
            sort: %{},
            pagination: %{},
            locale: "en",
            preloads: []
end