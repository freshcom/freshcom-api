defmodule BlueJet.EventHandler do
  @callback handle_event(String.t, any) :: {:ok, any}
end