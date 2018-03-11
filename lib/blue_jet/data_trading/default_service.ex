defmodule BlueJet.DataTrading.DefaultService do
  use BlueJet, :service

  alias BlueJet.DataTrading.DataImport

  @behaviour BlueJet.DataTrading.Service

  def create_data_import(fields, opts) do
    account_id = opts[:account_id] || opts[:account].id

    changeset =
      %DataImport{ account_id: account_id, account: opts[:account] }
      |> DataImport.changeset(:insert, fields)

    case Repo.insert(changeset) do
      {:ok, data_import} ->
        Task.start(fn -> DataImport.process(data_import, changeset) end)

      other -> other
    end
  end

  def delete_all_data_import(opts = %{ account: account = %{ mode: "test" } }) do
    bulk_size = opts[:bulk_size] || 1000

    data_import_ids =
      DataImport.Query.default()
      |> DataImport.Query.for_account(account.id)
      |> DataImport.Query.paginate(size: bulk_size, number: 1)
      |> DataImport.Query.id_only()
      |> Repo.all()

    DataImport.Query.default()
    |> DataImport.Query.filter_by(%{ id: data_import_ids })
    |> Repo.delete_all()

    if length(data_import_ids) === bulk_size do
      delete_all_data_import(opts)
    else
      :ok
    end
  end
end