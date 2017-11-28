defmodule RemoteCSV do
  def stream(path) do
    Stream.resource(fn -> start_stream(path) end,
                    &continue_stream/1,
                    fn(_) -> :ok end)
  end

  defp start_stream(path) do
    {:ok, _status, _headers, ref} = :hackney.get(path, [], "")

    {ref, ""}
  end

  defp continue_stream(:halt), do: {:halt, []}
  defp continue_stream({ref, partial_row}) do
    case :hackney.stream_body(ref) do
      {:ok, data} ->
        data = partial_row <> data

        if ends_with_line_break?(data) do
          rows = split(data)

          {rows, {ref, ""}}
        else
          {rows, partial_row} = extract_partial_row(data)

          {rows, {ref, partial_row}}
        end

      :done ->
        if partial_row == "" do
          {:halt, []}
        else
          {[partial_row], :halt}
        end

      {:error, reason} ->
        raise reason
    end
  end

  defp extract_partial_row(data) do
    data = split(data)
    rows = Enum.drop(data, -1)
    partial = List.last(data)

    {rows, partial}
  end

  defp split(data), do: String.split(data, ~r/(\r?\n|\r)/, trim: true)

  defp ends_with_line_break?(data), do: String.match?(data, ~r/(\r?\n|\r)$/)
end