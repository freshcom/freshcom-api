defmodule BlueJet.ContextRequest do
  defstruct vas: %{},

            # For list, create, get & update
            preloads: [],

            # For list, get & update
            locale: nil,

            # For get, update & delete
            identifiers: %{},

            # For create & update
            fields: %{},

            # For list
            params: %{},
            search: "",
            filter: %{},
            sort: %{},
            pagination: %{size: 25, number: 1},

            _vad_: %{
              account: nil,
              user: nil
            },
            _role_: nil,
            _preload_: %{
              paths: [],
              opts: %{}
            },
            _scope_: %{},
            _default_locale_: nil,
            _opts_: %{}

  @type t :: %__MODULE__{
    vas: %{account_id: binary, user_id: binary},
    preloads: list,
    locale: binary,
    identifiers: %{required(binary) => binary},
    fields: %{required(binary) => binary},
    params: %{required(binary) => binary},
    search: binary,
    filter: %{required(binary) => binary},
    sort: list,
    pagination: %{size: integer, number: integer},

    _vad_: %{account: map, user: map},
    _role_: binary,
    _preload_: %{paths: list, opts: map},
    _scope_: %{required(atom) => binary},
    _default_locale_: binary,
    _opts_: map
  }

  def put(req, root_key, key, value) do
    root_value =
      req
      |> Map.get(root_key)
      |> Map.put(key, value)

    Map.put(req, root_key, root_value)
  end

  def put(req, root_key, root_value) do
    Map.put(req, root_key, root_value)
  end

  def drop(req, root_key, keys) do
    root_value =
      req
      |> Map.get(root_key)
      |> Map.drop(keys)

    Map.put(req, root_key, root_value)
  end

  def valid_keys(:list) do
    [:params, :search, :filter, :sort, :pagination, :preloads, :locale]
  end

  def valid_keys(:create) do
    [:fields, :preloads, :locale]
  end

  def valid_keys(:get) do
    [:identifiers, :preloads, :locale]
  end

  def valid_keys(:update) do
    [:identifiers, :fields, :preloads, :locale]
  end

  def valid_keys(:delete) do
    [:identifiers]
  end
end