defmodule BlueJet.AccessRequest do
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
            counts: %{ all: %{} }, # TODO: Remove
            count_filter: %{ all: %{} },

            preloads: [],
            preload_filters: %{},
            locale: nil

  @type t :: map

  def transform_by_role(request = %{ role: role }) when role in ["guest", "customer"] do
    filter = Map.put(request.filter, :status, "active")
    counts = Map.put(request.counts, :all, %{ status: "active" })
    %{ request | filter: filter, counts: counts }
  end

  def transform_by_role(request), do: request

  def to_authorized_args(request, :list) do
    %{
      filter: request.filter,
      search: request.search,

      opts: %{
        account: request.account,
        pagination: request.pagination,
        preloads: %{ path: request.preloads, opts: %{ filters: request.preload_filters } },
        locale: request.locale
      }
    }
  end

  def to_authorized_args(request, :create) do
    %{
      fields: request.fields,

      opts: %{
        account: request.account,
        preloads: %{ path: request.preloads, opts: %{ filters: request.preload_filters } },
        locale: request.locale
      }
    }
  end

  def to_authorized_args(request, :update) do
    %{
      id: request.params["id"],
      fields: request.fields,

      opts: %{
        account: request.account,
        preloads: %{ path: request.preloads, opts: %{ filters: request.preload_filters } },
        locale: request.locale
      }
    }
  end

  def to_authorized_args(request, :get) do
    %{
      identifiers: %{ id: request.params["id"] },

      opts: %{
        account: request.account,
        preloads: %{ path: request.preloads, opts: %{ filters: request.preload_filters } },
        locale: request.locale
      }
    }
  end
end