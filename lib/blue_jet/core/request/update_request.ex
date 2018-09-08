defmodule BlueJet.UpdateRequest do
  defstruct vas: %{},
            identifiers: %{},
            fields: %{},
            preloads: [],
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
            _default_locale_: nil

  @type t :: map
end