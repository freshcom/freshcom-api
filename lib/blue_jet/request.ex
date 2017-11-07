defmodule BlueJet.AccessRequest do
  defstruct vas: %{},

            params: %{},
            fields: %{},

            search: "",
            filter: %{},
            sort: %{},
            pagination: %{},

            preloads: [],
            locale: "en"
end