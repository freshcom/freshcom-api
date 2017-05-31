defmodule BlueJet.Plugs.Pagination do
  import Plug.Conn

  def defaults do
    [
      number: 1,
      size:   50
    ]
  end

  def init(options) do
    Keyword.merge(defaults(), options)
  end

  def call(%Plug.Conn{ params: params } = conn, options) do
    params = params["page"] || %{}
    page_number = params |> Map.get("number", options[:number]) |> to_int
    page_size = params |> Map.get("size", options[:size]) |> to_int

    conn
    |> assign(:page_number, page_number)
    |> assign(:page_size, page_size)
  end

  defp to_int(i) when is_integer(i), do: i
  defp to_int(s) when is_binary(s) do
    case Integer.parse(s) do
      {i, _} -> i
      :error -> :error
    end
  end
end
