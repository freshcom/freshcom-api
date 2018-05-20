defmodule BlueJet.Service.Preload do
  alias BlueJet.Repo

  def preload([], _, _), do: []

  def preload(nil, _, _), do: nil

  def preload(struct_or_structs, path, opts) do
    struct_module = if is_list(struct_or_structs) do
      Enum.at(struct_or_structs, 0).__struct__
    else
      struct_or_structs.__struct__
    end
    query_module = Module.concat(struct_module, Query)
    proxy_module = Module.concat(struct_module, Proxy)
    preload_query = query_module.preloads(path, opts)

    struct_or_structs
    |> Repo.preload(preload_query)
    |> proxy_module.put(path, opts)
  end
end