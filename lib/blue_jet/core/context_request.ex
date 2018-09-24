defmodule BlueJet.ContextRequest do
  defstruct vas: %{},

            include: "",

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
            sort: [],
            pagination: %{size: 25, number: 1},

            _vad_: %{
              account: nil,
              user: nil
            },
            _role_: nil,
            _include_: %{
              paths: "",
              opts: %{}
            },
            _scope_: %{},
            _default_locale_: nil,
            _opts_: %{}

  @type t :: %__MODULE__{
    vas: %{account_id: String.t() | nil, user_id: String.t() | nil},
    include: String.t(),
    preloads: list,
    locale: String.t(),
    identifiers: %{required(String.t()) => String.t() | nil},
    fields: %{required(String.t()) => String.t() | nil},
    params: %{required(String.t()) => String.t()},
    search: String.t(),
    filter: %{required(String.t()) => String.t() | nil},
    sort: list,
    pagination: %{size: integer, number: integer},

    _vad_: %{account: map | nil, user: map | nil},
    _role_: String.t(),
    _include_: %{paths: String.t(), opts: map},
    _scope_: %{required(atom) => String.t() | nil},
    _default_locale_: String.t(),
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