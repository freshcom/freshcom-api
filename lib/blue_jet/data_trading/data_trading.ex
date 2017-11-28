defmodule BlueJet.DataTrading do
  use BlueJet, :context

  alias BlueJet.Identity
  alias BlueJet.Storefront

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

  def import_from_stream() do

  end
  def import_data(import_data = %{ data_url: data_url, data_type: "Customer" }) do
    stream = RemoteCSV.stream(data_url) |> CSV.decode(headers: true)

    Repo.transaction(fn ->
      stream
      |> Stream.chunk_every(3)
      |> Enum.each(fn(chunk) ->
          Enum.each(chunk, fn({:ok, row}) ->
            enroller_id = cond do
              row["enroller_id"] && row["enroller_id"] != "" -> row["enroller_id"]
              row["enroller_code"] && row["enroller_code"] != "" ->
                result = Storefront.do_get_customer(%AccessRequest{
                  vas: %{ account_id: import_data.account_id },
                  params: %{ code: row["enroller_code"] }
                })

                case result do
                  {:ok, %{ data: enroller}} -> enroller.id
                  other -> nil
                end
            end

            sponsor_id = cond do
              row["sponsor_id"] && row["sponsor_id"] != "" -> row["sponsor_id"]
              row["sponsor_code"] && row["sponsor_code"] != "" ->
                result = Storefront.do_get_customer(%AccessRequest{
                  vas: %{ account_id: import_data.account_id },
                  params: %{ code: row["sponsor_code"] }
                })

                case result do
                  {:ok, %{ data: sponsor}} -> sponsor.id
                  other -> nil
                end
            end

            customer = if row["id"] && row["id"] != "" do
              {:ok, %{ data: sponsor}} = Storefront.do_get_customer(%AccessRequest{
                vas: %{ account_id: import_data.account_id },
                params: %{ id: row["id"] }
              })
            else
              result = Storefront.do_get_customer(%AccessRequest{
                vas: %{ account_id: import_data.account_id },
                params: %{ code: row["code"] }
              })

              case result do
                {:ok, %{ data: customer }} ->
                  customer
                {:error, :not_found} -> nil
              end
            end

            custom_data = case row["custom_data"]  do
              nil -> nil
              "" -> %{}
              json -> Poison.decode!(json)
            end

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

            case customer do
              nil ->
                {:ok, response} = Storefront.do_create_customer(%AccessRequest{
                  vas: %{ account_id: import_data.account_id },
                  fields: fields
                })
              customer ->
                {:ok, response} = Storefront.do_update_customer(%AccessRequest{
                  vas: %{ account_id: import_data.account_id },
                  params: %{ customer_id: customer.id },
                  fields: fields
                })
            end
          end)
         end)
    end)
  end
end