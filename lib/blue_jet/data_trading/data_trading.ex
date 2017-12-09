defmodule BlueJet.DataTrading do
  use BlueJet, :context

  alias BlueJet.Identity
  alias BlueJet.CRM
  alias BlueJet.Goods
  alias BlueJet.Catalogue

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

    fields =
      merge_custom_data(row, row["custom_data"])
      |> Map.merge(%{
          "sponsor_id" => sponsor_id,
          "enroller_id" => enroller_id
        })

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
    fields = merge_custom_data(row, row["custom_data"])

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
  def import_resource(row, account_id, "Product") do
    source_id = extract_product_source_id(row, account_id)
    collection_id = extract_product_collection_id(row, account_id, "collection")

    fields =
      merge_custom_data(row, row["custom_data"])
      |> Map.merge(%{ "source_id" => source_id })

    product =
      get_product(row, account_id)
      |> update_or_create_product(account_id, fields)

    if collection_id do
      Catalogue.do_create_product_collection_membership(%AccessRequest{
        vas: %{ account_id: account_id },
        fields: %{ "product_id" => product.id, "collection_id" => collection_id, "sort_index" => row["collection_sort_index"] }
      })
    end
  end

  defp extract_product_source_id(%{ "source_id" => source_id }, account_id) when byte_size(source_id) > 0 do
    source_id
  end
  defp extract_product_source_id(%{ "source_code" => code, "source_type" => "Unlockable" }, account_id) when byte_size(code) > 0 do
    result = Goods.do_get_unlockable(%AccessRequest{
      vas: %{ account_id: account_id },
      params: %{ "code" => code }
    })

    case result do
      {:ok, %{ data: unlockable }} ->
        unlockable.id
      {:error, :not_found} -> nil
    end
  end

  defp rel_id_key(nil), do: "id"
  defp rel_id_key(rel_name), do: "#{rel_name}_id"
  defp rel_code_key(nil), do: "code"
  defp rel_code_key(rel_name), do: "#{rel_name}_code"

  defp extract_customer_id(row, account_id, rel_name \\ nil) do
    id_key = rel_id_key(rel_name)
    code_key = rel_code_key(rel_name)

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
      true -> nil
    end
  end

  defp extract_product_collection_id(row, account_id, rel_name \\ nil) do
    id_key = rel_id_key(rel_name)
    code_key = rel_code_key(rel_name)

    cond do
      row[id_key] && row[id_key] != "" -> row[id_key]
      row[code_key] && row[code_key] != "" ->
        result = Catalogue.do_get_product_collection(%AccessRequest{
          vas: %{ account_id: account_id },
          params: %{ "code" => row[code_key] }
        })

        case result do
          {:ok, %{ data: product_collection}} -> product_collection.id
          other -> nil
        end
      true -> nil
    end
  end

  defp get_customer(%{ "id" => id }, account_id) when byte_size(id) > 0 do
    {:ok, %{ data: customer}} = CRM.do_get_customer(%AccessRequest{
      vas: %{ account_id: account_id },
      params: %{ "id" => id }
    })

    customer
  end
  defp get_customer(%{ "code" => code }, account_id) when byte_size(code) > 0 do
    result = CRM.do_get_customer(%AccessRequest{
      vas: %{ account_id: account_id },
      params: %{ "code" => code }
    })

    case result do
      {:ok, %{ data: customer }} ->
        customer
      {:error, :not_found} -> nil
    end
  end

  defp get_unlockable(%{ "id" => id }, account_id) when byte_size(id) > 0 do
    {:ok, %{ data: unlockable}} = Goods.do_get_unlockable(%AccessRequest{
      vas: %{ account_id: account_id },
      params: %{ "id" => id }
    })

    unlockable
  end
  defp get_unlockable(%{ "code" => code }, account_id) when byte_size(code) > 0 do
    result = Goods.do_get_unlockable(%AccessRequest{
      vas: %{ account_id: account_id },
      params: %{ "code" => code }
    })

    case result do
      {:ok, %{ data: unlockable }} ->
        unlockable
      {:error, :not_found} -> nil
    end
  end

  defp get_product(%{ "id" => id }, account_id) when byte_size(id) > 0 do
    {:ok, %{ data: product}} = Catalogue.do_get_product(%AccessRequest{
      vas: %{ account_id: account_id },
      params: %{ "id" => id }
    })

    product
  end
  defp get_product(%{ "code" => code }, account_id) when byte_size(code) > 0 do
    result = Catalogue.do_get_product(%AccessRequest{
      vas: %{ account_id: account_id },
      params: %{ "code" => code }
    })

    case result do
      {:ok, %{ data: product }} ->
        product
      {:error, :not_found} -> nil
    end
  end

  defp get_product_collection(%{ "id" => id }, account_id) when byte_size(id) > 0 do
    {:ok, %{ data: product_collection}} = Catalogue.do_get_product_collection(%AccessRequest{
      vas: %{ account_id: account_id },
      params: %{ "id" => id }
    })

    product_collection
  end
  defp get_product_collection(%{ "code" => code }, account_id) when byte_size(code) > 0 do
    result = Catalogue.do_get_product_collection(%AccessRequest{
      vas: %{ account_id: account_id },
      params: %{ "code" => code }
    })

    case result do
      {:ok, %{ data: product_collection }} ->
        product_collection
      {:error, :not_found} -> nil
    end
  end

  defp update_or_create_product(nil, account_id, fields) do
    {:ok, %{ data: product }} = Catalogue.do_create_product(%AccessRequest{
      vas: %{ account_id: account_id },
      fields: fields
    })
    product
  end
  defp update_or_create_product(product, account_id, fields) do
    {:ok, %{ data: product }} = Catalogue.do_update_product(%AccessRequest{
      vas: %{ account_id: account_id },
      params: %{ "id" => product.id },
      fields: fields
    })
    product
  end

  defp merge_custom_data(row, nil), do: row
  defp merge_custom_data(row, ""), do: Map.merge(row, %{ "custom_data" => %{} })
  defp merge_custom_data(json), do: Map.merge(row, %{ "custom_data" => Poison.decode!(json) })
end