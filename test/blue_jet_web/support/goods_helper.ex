defmodule BlueJet.Goods.TestHelper do
  alias BlueJet.ContextRequest
  alias BlueJet.Goods

  def create_stockable(user) do
    {:ok, %{data: stockable}} = Goods.create_stockable(%ContextRequest{
      fields: %{
        "name" => Faker.Commerce.product_name(),
        "unit_of_measure" => "EA"
      },
      vas: %{ account_id: user.default_account_id, user_id: user.id }
    })

    stockable
  end
end