# defmodule BlueJet.Goods.TestHelper do
#   alias BlueJet.Goods.Service

#   def stockable_fixture(account, fields \\ %{}) do
#     default_fields = %{
#       name: Faker.Commerce.product_name(),
#       unit_of_measure: "EA",
#       translations: %{
#         "zh-CN" => %{
#           "name" => Enum.random(["苹果", "橙子", "芒果", "桃子", "西瓜"])
#         }
#       }
#     }
#     fields = Map.merge(default_fields, fields)

#     {:ok, stockable} = Service.create_stockable(fields, %{account: account})

#     stockable
#   end

#   def unlockable_fixture(account, fields \\ %{}) do
#     default_fields = %{
#       name: Faker.Commerce.product_name(),
#       translations: %{
#         "zh-CN" => %{
#           "name" => Enum.random(["苹果", "橙子", "芒果", "桃子", "西瓜"])
#         }
#       }
#     }
#     fields = Map.merge(default_fields, fields)

#     {:ok, unlockable} = Service.create_unlockable(fields, %{account: account})

#     unlockable
#   end

#   def depositable_fixture(account, fields \\ %{}) do
#     default_fields = %{
#       name: Faker.Commerce.product_name(),
#       gateway: "freshcom",
#       amount: System.unique_integer([:positive]),
#       translations: %{
#         "zh-CN" => %{
#           "name" => Enum.random(["苹果", "橙子", "芒果", "桃子", "西瓜"])
#         }
#       }
#     }
#     fields = Map.merge(default_fields, fields)

#     {:ok, depositable} = Service.create_depositable(fields, %{account: account})

#     depositable
#   end
# end
