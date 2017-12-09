defmodule BlueJet.DataTrading do
  use BlueJet, :context

  alias BlueJet.Identity
  alias BlueJet.CRM
  alias BlueJet.Goods

  alias BlueJet.DataTrading.DataImport

  def create_data_import(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "data_trading.create_data_import") do
      do_create_data_import(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_create_data_import(request = %{ vas: vas }) do
    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id], "customer_id" => vas[:customer_id] || request.fields["customer_id"] })
    changeset = DataImport.changeset(%DataImport{}, fields)

    with {:ok, data_import} <- Repo.insert(changeset) do
      Task.start(fn ->
        import_data(data_import)
      end)

      {:ok, %AccessResponse{}}
    else
      {:error, changeset} ->
        {:error, %AccessResponse{ errors: changeset.errors }}
    end
  end

  def import_data(import_data = %{ data_url: data_url, data_type: data_type }) do
    stream = RemoteCSV.stream(data_url) |> CSV.decode(headers: true)

    Repo.transaction(fn ->
      stream
      |> Stream.chunk_every(100)
      |> Enum.each(fn(chunk) ->
          Enum.each(chunk, fn({:ok, row}) ->
           import_resource(row, import_data.account_id, data_type)
          end)
         end)
    end)
  end

  def import_resource(row, account_id, "Customer") do
    enroller_id = extract_customer_id(row, account_id, "enroller")
    sponsor_id = extract_customer_id(row, account_id, "sponsor")
    custom_data = extract_customer_data(row["custom_data"])

    fields = if custom_data do
      Map.merge(row, %{
        "sponsor_id" => sponsor_id,
        "enroller_id" => enroller_id,
        "custom_data" => custom_data
      })
    else
      Map.merge(row, %{
        "sponsor_id" => sponsor_id,
        "enroller_id" => enroller_id
      })
    end

    customer = get_customer(row, account_id)
    case customer do
      nil ->
        {:ok, response} = CRM.do_create_customer(%AccessRequest{
          vas: %{ account_id: account_id },
          fields: fields
        })
      customer ->
        {:ok, response} = CRM.do_update_customer(%AccessRequest{
          vas: %{ account_id: account_id },
          params: %{ "id" => customer.id },
          fields: fields
        })
    end
  end
  def import_resource(row, account_id, "Unlockable") do
    custom_data = extract_customer_data(row["custom_data"])

    fields = if custom_data do
      Map.merge(row, %{
        "custom_data" => custom_data
      })
    else
      row
    end

    unlockable = get_unlockable(row, account_id)
    case unlockable do
      nil ->
        {:ok, response} = Goods.do_create_unlockable(%AccessRequest{
          vas: %{ account_id: account_id },
          fields: fields
        })
      unlockable ->
        {:ok, response} = Goods.do_update_unlockable(%AccessRequest{
          vas: %{ account_id: account_id },
          params: %{ "id" => unlockable.id },
          fields: fields
        })
    end
  end

  defp get_customer(row, account_id) do
    if row["id"] && row["id"] != "" do
      {:ok, %{ data: sponsor}} = CRM.do_get_customer(%AccessRequest{
        vas: %{ account_id: account_id },
        params: %{ "id" => row["id"] }
      })
    else
      result = CRM.do_get_customer(%AccessRequest{
        vas: %{ account_id: account_id },
        params: %{ "code" => row["code"] }
      })

      case result do
        {:ok, %{ data: customer }} ->
          customer
        {:error, :not_found} -> nil
      end
    end
  end

  defp extract_customer_id(row, account_id, relationship_name \\ nil) do
    id_key = if relationship_name do
      "#{relationship_name}_id"
    else
      "id"
    end

     code_key = if relationship_name do
      "#{relationship_name}_code"
    else
      "code"
    end

    cond do
      row[id_key] && row[id_key] != "" -> row[id_key]
      row[code_key] && row[code_key] != "" ->
        result = CRM.do_get_customer(%AccessRequest{
          vas: %{ account_id: account_id },
          params: %{ "code" => row[code_key] }
        })

        case result do
          {:ok, %{ data: customer}} -> customer.id
          other -> nil
        end
    end
  end

  defp get_unlockable(row, account_id) do
    if row["id"] && row["id"] != "" do
      {:ok, %{ data: sponsor}} = Goods.do_get_unlockable(%AccessRequest{
        vas: %{ account_id: account_id },
        params: %{ "id" => row["id"] }
      })
    else
      result = Goods.do_get_unlockable(%AccessRequest{
        vas: %{ account_id: account_id },
        params: %{ "code" => row["code"] }
      })

      case result do
        {:ok, %{ data: unlockable }} ->
          unlockable
        {:error, :not_found} -> nil
      end
    end
  end

  defp extract_customer_data(nil), do: nil
  defp extract_customer_data(""), do: %{}
  defp extract_customer_data(json), do: Poison.decode!(json)
end