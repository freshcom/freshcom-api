defmodule BlueJet.Policy.AuthorizedRequest do
  def from_access_request(request, :list) do
    default_locale = (request.account || %{ default_locale: nil }).default_locale
    locale = request.locale || default_locale

    %{
      filter: request.filter,
      search: request.search,

      all_count_filter: %{},

      locale: locale,
      default_locale: default_locale,

      opts: %{
        account: request.account,
        pagination: request.pagination,
        preloads: %{ path: request.preloads, opts: %{ filters: request.preload_filters } },
        locale: request.locale
      }
    }
  end

  def from_access_request(request, :create) do
    default_locale = (request.account || %{ default_locale: nil }).default_locale
    locale = request.locale || default_locale

    %{
      fields: request.fields,

      opts: %{
        account: request.account,
        preloads: %{ path: request.preloads, opts: %{ filters: request.preload_filters } },
        locale: locale
      }
    }
  end

  def from_access_request(request, :get) do
    default_locale = (request.account || %{ default_locale: nil }).default_locale
    locale = request.locale || default_locale

    %{
      identifiers: %{ id: request.params["id"] },

      locale: locale,
      default_locale: default_locale,

      opts: %{
        account: request.account,
        preloads: %{ path: request.preloads, opts: %{ filters: request.preload_filters } },
        locale: request.locale
      }
    }
  end

  def from_access_request(request, :update) do
    default_locale = (request.account || %{ default_locale: nil }).default_locale
    locale = request.locale || default_locale

    %{
      id: request.params["id"],

      identifiers: %{ id: request.params["id"] },
      fields: request.fields,

      locale: locale,
      default_locale: default_locale,

      opts: %{
        account: request.account,
        preloads: %{ path: request.preloads, opts: %{ filters: request.preload_filters } },
        locale: request.locale
      }
    }
  end

  def from_access_request(request, :delete) do
    %{
      id: request.params["id"],

      identifiers: %{ id: request.params["id"] },

      opts: %{
        account: request.account
      }
    }
  end
end