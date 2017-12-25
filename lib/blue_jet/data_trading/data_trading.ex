defmodule BlueJet.DataTrading do
  use BlueJet, :context

  alias BlueJet.CRM
  alias BlueJet.Goods
  alias BlueJet.Catalogue

  alias BlueJet.DataTrading.DataImport

  def create_data_import(request) do
    with {:ok, request} <- preprocess_request(request, "data_trading.create_data_import") do
      request
      |> do_create_data_import()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_data_import(request = %{ account: account }) do
    fields = Map.merge(request.fields, %{ "account_id" => account.id })
    changeset = DataImport.changeset(%DataImport{}, fields)

    with {:ok, data_import} <- Repo.insert(changeset) do
      data_import = %{ data_import | account: account }
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
           row = process_csv_row(row)
           import_resource(row, import_data.account, data_type)
          end)
         end)
    end)
  end

  defp process_csv_row(row) do
    Enum.reduce(row, %{}, fn({k, v}, acc) ->
      case v do
        "true" -> Map.put(acc, k, true)
        "false" -> Map.put(acc, k, false)
        other -> Map.put(acc, k, other)
      end
    end)
  end

  def import_resource(row, account, "Customer") do
    enroller_id = extract_customer_id(row, account, "enroller")
    sponsor_id = extract_customer_id(row, account, "sponsor")

    fields =
      merge_custom_data(row, row["custom_data"])
      |> Map.merge(%{
          "sponsor_id" => sponsor_id,
          "enroller_id" => enroller_id
        })

    customer = get_customer(row, account)
    case customer do
      nil ->
        {:ok, _} = CRM.do_create_customer(%AccessRequest{
          account: account,
          fields: fields
        })
      customer ->
        {:ok, _} = CRM.do_update_customer(%AccessRequest{
          account: account,
          params: %{ "id" => customer.id },
          fields: fields
        })
    end
  end
  def import_resource(row, account, "Unlockable") do
    fields = merge_custom_data(row, row["custom_data"])

    unlockable = get_unlockable(row, account)
    case unlockable do
      nil ->
        {:ok, _} = Goods.do_create_unlockable(%AccessRequest{
          account: account,
          fields: fields
        })
      unlockable ->
        {:ok, _} = Goods.do_update_unlockable(%AccessRequest{
          account: account,
          params: %{ "id" => unlockable.id },
          fields: fields,
          locale: account.default_locale
        })
    end
  end
  def import_resource(row, account, "Product") do
    source_id = extract_product_source_id(row, account)
    collection_id = extract_product_collection_id(row, account, "collection")

    fields =
      merge_custom_data(row, row["custom_data"])
      |> Map.merge(%{ "source_id" => source_id })

    product =
      get_product(row, account)
      |> update_or_create_product(account, fields)

    result = Catalogue.do_get_product_collection_membership(%AccessRequest{
      account: account,
      params: %{ "collection_id" => collection_id, "product_id" => product.id }
    })

    case result do
      {:ok, response} -> {:ok, response}
      {:error, :not_found} ->
        Catalogue.do_create_product_collection_membership(%AccessRequest{
          account: account,
          fields: %{ "product_id" => product.id, "collection_id" => collection_id, "sort_index" => row["collection_sort_index"] }
        })
    end
  end
  def import_resource(row, account, "Price") do
    product_id = extract_product_id(row, account, "product")

    fields =
      merge_custom_data(row, row["custom_data"])
      |> Map.merge(%{ "product_id" => product_id })

    get_price(row, account)
    |> update_or_create_price(account, fields)
  end

  defp extract_product_source_id(%{ "source_id" => source_id }, _) when byte_size(source_id) > 0 do
    source_id
  end
  defp extract_product_source_id(%{ "source_code" => code, "source_type" => "Unlockable" }, account) when byte_size(code) > 0 do
    result = Goods.do_get_unlockable(%AccessRequest{
      account: account,
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

  defp extract_customer_id(row, account, rel_name) do
    id_key = rel_id_key(rel_name)
    code_key = rel_code_key(rel_name)

    cond do
      row[id_key] && row[id_key] != "" -> row[id_key]
      row[code_key] && row[code_key] != "" ->
        result = CRM.do_get_customer(%AccessRequest{
          account: account,
          params: %{ "code" => row[code_key] }
        })

        case result do
          {:ok, %{ data: customer}} -> customer.id
          _ -> nil
        end
      true -> nil
    end
  end

  defp extract_product_id(row, account, rel_name) do
    id_key = rel_id_key(rel_name)
    code_key = rel_code_key(rel_name)

    cond do
      row[id_key] && row[id_key] != "" -> row[id_key]
      row[code_key] && row[code_key] != "" ->
        result = Catalogue.do_get_product(%AccessRequest{
          account: account,
          params: %{ "code" => row[code_key] }
        })

        case result do
          {:ok, %{ data: product}} -> product.id
          _ -> nil
        end
      true -> nil
    end
  end

  defp extract_product_collection_id(row, account, rel_name) do
    id_key = rel_id_key(rel_name)
    code_key = rel_code_key(rel_name)

    cond do
      row[id_key] && row[id_key] != "" -> row[id_key]
      row[code_key] && row[code_key] != "" ->
        result = Catalogue.do_get_product_collection(%AccessRequest{
          account: account,
          params: %{ "code" => row[code_key] }
        })

        case result do
          {:ok, %{ data: product_collection}} -> product_collection.id
          _ -> nil
        end
      true -> nil
    end
  end

  defp get_customer(%{ "id" => id }, account) when byte_size(id) > 0 do
    {:ok, %{ data: customer}} = CRM.do_get_customer(%AccessRequest{
      account: account,
      params: %{ "id" => id }
    })

    customer
  end
  defp get_customer(%{ "code" => code }, account) when byte_size(code) > 0 do
    result = CRM.do_get_customer(%AccessRequest{
      account: account,
      params: %{ "code" => code }
    })

    case result do
      {:ok, %{ data: customer }} ->
        customer
      {:error, :not_found} -> nil
    end
  end

  defp get_unlockable(%{ "id" => id }, account) when byte_size(id) > 0 do
    {:ok, %{ data: unlockable}} = Goods.do_get_unlockable(%AccessRequest{
      account: account,
      params: %{ "id" => id }
    })

    unlockable
  end
  defp get_unlockable(%{ "code" => code }, account) when byte_size(code) > 0 do
    result = Goods.do_get_unlockable(%AccessRequest{
      account: account,
      params: %{ "code" => code }
    })

    case result do
      {:ok, %{ data: unlockable }} ->
        unlockable
      {:error, :not_found} -> nil
    end
  end

  defp get_product(%{ "id" => id }, account) when byte_size(id) > 0 do
    {:ok, %{ data: product}} = Catalogue.do_get_product(%AccessRequest{
      account: account,
      params: %{ "id" => id }
    })

    product
  end
  defp get_product(%{ "code" => code }, account) when byte_size(code) > 0 do
    result = Catalogue.do_get_product(%AccessRequest{
      account: account,
      params: %{ "code" => code }
    })

    case result do
      {:ok, %{ data: product }} ->
        product
      {:error, :not_found} -> nil
    end
  end

  defp get_price(%{ "id" => id }, account) when byte_size(id) > 0 do
    {:ok, %{ data: price}} = Catalogue.do_get_price(%AccessRequest{
      account: account,
      params: %{ "id" => id }
    })

    price
  end
  defp get_price(%{ "code" => code }, account) when byte_size(code) > 0 do
    result = Catalogue.do_get_price(%AccessRequest{
      account: account,
      params: %{ "code" => code }
    })

    case result do
      {:ok, %{ data: price }} ->
        price
      {:error, :not_found} -> nil
    end
  end

  defp update_or_create_product(nil, account, fields) do
    {:ok, %{ data: product }} = Catalogue.do_create_product(%AccessRequest{
      account: account,
      fields: fields
    })
    product
  end
  defp update_or_create_product(product, account, fields) do
    {:ok, %{ data: product }} = Catalogue.do_update_product(%AccessRequest{
      account: account,
      params: %{ "id" => product.id },
      fields: fields
    })
    product
  end

  defp update_or_create_price(nil, account, fields) do
    {:ok, %{ data: price }} = Catalogue.do_create_price(%AccessRequest{
      account: account,
      fields: fields
    })
    price
  end
  defp update_or_create_price(price, account, fields) do
    {:ok, %{ data: price }} = Catalogue.do_update_price(%AccessRequest{
      account: account,
      params: %{ "id" => price.id },
      fields: fields
    })
    price
  end

  defp merge_custom_data(row, nil), do: row
  defp merge_custom_data(row, ""), do: Map.merge(row, %{ "custom_data" => %{} })
  defp merge_custom_data(row, json) do
    Map.merge(row, %{ "custom_data" => Poison.decode!(json) })
  end
end