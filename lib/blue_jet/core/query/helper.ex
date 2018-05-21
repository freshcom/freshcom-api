defmodule BlueJet.Query.Helper do
  import Ecto.Query

  def get_preload_filter(opts, key) do
    filters = opts[:filters] || %{}
    filters[key] || %{}
  end
end