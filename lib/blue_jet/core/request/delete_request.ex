defmodule BlueJet.DeleteRequest do
  defstruct vas: %{},
            identifiers: %{},

            _vad_: %{
              account: nil,
              user: nil
            },
            _role_: nil,
            _default_locale_: nil

  @type t :: map
end