defmodule BlueJet.DataTrading.Service do
  use BlueJet, :service

  alias BlueJet.DataTrading.DataImport

  def create_data_import(fields, opts) do
    account_id = opts[:account_id] || opts[:account].id

    changeset =
      %DataImport{account_id: account_id, account: opts[:account]}
      |> DataImport.changeset(:insert, fields)

    case Repo.insert(changeset) do
      {:ok, data_import} ->
        Task.start(fn -> DataImport.process(data_import, changeset) end)
        {:ok, data_import}

      other ->
        other
    end
  end

  def delete_all_data_import(opts) do
    delete_all(DataImport, opts)
  end
end
