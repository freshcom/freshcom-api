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

            preloads: [],
            preload_filters: %{},
            locale: nil

  @type t :: map

  def to_authorized_args(request, :list) do
    %{
      filter: request.filter,
      search: request.search,

      all_count_filter: %{},

      locale: request.locale,
      default_locale: (request.account || %{ default_locale: nil }).default_locale,

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

  def to_authorized_args(request, :get) do
    %{
      identifiers: %{ id: request.params["id"] },

      locale: request.locale,
      default_locale: (request.account || %{ default_locale: nil }).default_locale,

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

      identifiers: %{ id: request.params["id"] },
      fields: request.fields,

      locale: request.locale,
      default_locale: (request.account || %{ default_locale: nil }).default_locale,

      opts: %{
        account: request.account,
        preloads: %{ path: request.preloads, opts: %{ filters: request.preload_filters } },
        locale: request.locale
      }
    }
  end

  def to_authorized_args(request, :delete) do
    %{
      id: request.params["id"],

      identifiers: %{ id: request.params["id"] },

      opts: %{
        account: request.account
      }
    }
  end
end