defmodule BlueJet.ListRequest do
  defstruct vas: %{},
            params: %{},
            search: "",
            filter: %{},
            preloads: [],
            sort: %{},
            pagination: %{size: 25, number: 1},
            locale: nil,

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
            _default_locale_: nil

  @type t :: map
end