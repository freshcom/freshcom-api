defmodule BlueJet.Storefront do
  use BlueJet.Web, :context

  alias BlueJet.Product

  ######
  # Product
  ######
  def create_product(request = %{ vas: vas }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)

    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })
    changeset = Product.changeset(%Product{}, fields)

    with {:ok, product} <- Repo.insert(changeset) do
      product = Repo.preload(product, request.preloads)
      {:ok, product}
    else
      other -> other
    end
  end

end
