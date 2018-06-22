defmodule BlueJet.FileStorage.File.Query do
  use BlueJet, :query

  use BlueJet.Query.Search,
    for: [
      :name,
      :content_type,
      :code,
      :id
    ]

  use BlueJet.Query.Filter,
    for: [
      :id,
      :status,
      :label,
      :content_type
    ]

  alias BlueJet.FileStorage.File

  def default() do
    from(f in File)
  end

  def uploaded(query) do
    from(f in query, where: f.status == "uploaded")
  end
end
