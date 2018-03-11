defmodule BlueJet.DataTrading do
  use BlueJet, :context

  alias BlueJet.DataTrading.Service

  def create_data_import(request) do
    with {:ok, request} <- preprocess_request(request, "data_trading.create_data_import") do
      request
      |> do_create_data_import()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_data_import(request = %{ account: account }) do
    with {:ok, _} <- Service.create_data_import(request.fields, %{ account: account }) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  # def import_data(import_data = %{ data_url: data_url, data_type: data_type }) do
  #   stream = RemoteCSV.stream(data_url) |> CSV.decode(headers: true)
  #   stream
  #   |> Stream.chunk_every(1000)
  #   |> Enum.each(fn(chunk) ->
  #       Repo.transaction(fn ->
  #         Enum.each(chunk, fn({:ok, row}) ->
  #          row = process_csv_row(row)
  #          import_resource(row, import_data.account, data_type)
  #         end)
  #       end)
  #      end)
  # end
end