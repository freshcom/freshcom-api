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

  def transform_by_role(request = %{ role: role }) when role in ["guest", "customer"] do
    filter = Map.put(request.filter, :status, "active")
    counts = Map.put(request.counts, :all, %{ status: "active" })
    %{ request | filter: filter, counts: counts }
  end

  def transform_by_role(request), do: request
end