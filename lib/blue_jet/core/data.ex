defmodule BlueJet.Data do
  @moduledoc """
  Defines the functions that a data module should implement in order to be
  used with default service functions.

  Callbacks defined in this behaviour are used in `BlueJet.Service.default_*`
  functions. If you wish to use those default functions for your specific data
  module, then that data module must implement this behaviour, otherwise you
  are not required to use this behaviour.
  """
  alias Ecto.Changeset

  @callback changeset(data :: struct, action :: :insert, fields :: map) :: Changeset.t()

  @callback changeset(data :: struct, action :: :update, fields :: map, locale :: String.t() | nil) :: Changeset.t()

  @callback changeset(data :: struct, action :: :delete) :: Changeset.t()
end