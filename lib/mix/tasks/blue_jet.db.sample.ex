defmodule Mix.Tasks.BlueJet.Db.Sample do
  use Mix.Task

  @shortdoc "Add initial account for alpha release"

  @moduledoc """
    This is where we would put any long form documentation or doctests.
  """

  def run(args) do
    alias BlueJet.Repo

    alias BlueJet.{Identity, Goods, Catalogue, Crm}
    alias BlueJet.Identity.Account
    alias BlueJet.AccessRequest

    Application.ensure_all_started(:blue_jet)
    # Application.ensure_all_started(:bamboo)

    Repo.transaction(fn ->
      {:ok, %{ data: user }} = Identity.create_user(%AccessRequest{
        fields: %{
          "name" => "Test User",
          "username" => "test@example.com",
          "email" => "test@example.com",
          "password" => "test1234",
          "default_locale" => "en"
        }
      })

      account = Repo.get_by(Account, id: user.default_account_id)
      test_account = Repo.get_by(Account, mode: "test", live_account_id: account.id)

      #
      # MARK: Customer
      #
      {:ok, _} = Crm.create_customer(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "status" => "guest",
          "first_name" => "Roy",
          "last_name" => "Bao"
        }
      })

      email = Faker.Internet.safe_email()
      {:ok, _} = Crm.create_customer(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "status" => "registered",
          "username" => email,
          "password" => "test1234",
          "first_name" => Faker.Name.first_name(),
          "last_name" => Faker.Name.last_name(),
          "email" => email
        }
      })

      email = Faker.Internet.safe_email()
      {:ok, _} = Crm.create_customer(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "status" => "registered",
          "username" => email,
          "password" => "test1234",
          "first_name" => Faker.Name.first_name(),
          "last_name" => Faker.Name.last_name(),
          "email" => email
        }
      })

      #
      # MARK: $50 Gift Card
      #
      {:ok, %{ data: depositable_50 }} = Goods.create_depositable(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "status" => "active",
          "name" => "$50 Gift Card",
          "code" => "GC50",
          "gateway" => "freshcom",
          "amount" => 5000
        }
      })

      {:ok, _} = Goods.update_depositable(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => depositable_50.id },
        fields: %{
          "name" => "$50礼品卡"
        },
        locale: "zh-CN"
      })

      {:ok, %{ data: product_gift_card_50 }} = Catalogue.create_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "code" => "GC50",
          "name_sync" => "sync_with_goods",
          "goods_id" => depositable_50.id,
          "goods_type" => "Depositable",
          "auto_fulfill" => true
        }
      })

      {:ok, _} = Catalogue.create_price(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "product_id" => product_gift_card_50.id },
        fields: %{
          "status" => "active",
          "name" => "Regular",
          "charge_amount_cents" => 5000,
          "charge_unit" => "EA"
        }
      })

      {:ok, _} = Catalogue.update_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => product_gift_card_50.id },
        fields: %{
          "status" => "active"
        }
      })

      #
      # MARK: $100 Gift Card
      #
      {:ok, %{ data: depositable_100 }} = Goods.create_depositable(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "status" => "active",
          "name" => "$100 Gift Card",
          "code" => "GC100",
          "gateway" => "freshcom",
          "amount" => 10000
        }
      })

      {:ok, _} = Goods.update_depositable(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => depositable_100.id },
        fields: %{
          "name" => "$100礼品卡"
        },
        locale: "zh-CN"
      })

      {:ok, %{ data: product_gift_card_100 }} = Catalogue.create_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "code" => "GC100",
          "name_sync" => "sync_with_goods",
          "goods_id" => depositable_100.id,
          "goods_type" => "Depositable",
          "auto_fulfill" => true
        }
      })

      {:ok, %{ data: price }} = Catalogue.create_price(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "product_id" => product_gift_card_100.id },
        fields: %{
          "status" => "active",
          "name" => "Regular",
          "charge_amount_cents" => 10000,
          "charge_unit" => "EA"
        }
      })

      {:ok, _} = Catalogue.update_price(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => price.id },
        fields: %{
          "name" => "原价",
          "charge_unit" => "个"
        },
        locale: "zh-CN"
      })

      {:ok, %{ data: price }} = Catalogue.create_price(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "product_id" => product_gift_card_100.id },
        fields: %{
          "status" => "active",
          "name" => "Bulk",
          "charge_amount_cents" => 9500,
          "charge_unit" => "EA",
          "minimum_order_quantity" => 5
        }
      })

      {:ok, _} = Catalogue.update_price(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => price.id },
        fields: %{
          "name" => "团购价",
          "charge_unit" => "个"
        },
        locale: "zh-CN"
      })

      {:ok, _} = Catalogue.update_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => product_gift_card_100.id },
        fields: %{
          "status" => "active"
        }
      })

      {:ok, %{ data: collection_gift_card }} = Catalogue.create_product_collection(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "status" => "active",
          "name" => "Gift Cards",
          "code" => "GC",
          "label" => "gift_card",
          "sort_index" => 900
        }
      })

      {:ok, _} = Catalogue.update_product_collection(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => collection_gift_card.id },
        fields: %{
          "name" => "礼品卡"
        },
        locale: "zh-CN"
      })

      {:ok, _} = Catalogue.create_product_collection_membership(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "collection_id" => collection_gift_card.id,
          "product_id" => product_gift_card_50.id,
          "sort_index" => 900
        }
      })

      {:ok, _} = Catalogue.create_product_collection_membership(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "collection_id" => collection_gift_card.id,
          "product_id" => product_gift_card_100.id,
          "sort_index" => 1000
        }
      })

      #
      # MARK: Game
      #
      {:ok, %{ data: unlockable_game }} = Goods.create_unlockable(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "status" => "active",
          "name" => "A PC Game",
          "code" => "AG001"
        }
      })

      {:ok, _} = Goods.update_unlockable(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => unlockable_game.id },
        fields: %{
          "name" => "一款电脑游戏"
        },
        locale: "zh-CN"
      })

      {:ok, %{ data: product_game }} = Catalogue.create_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "code" => "AG001",
          "name_sync" => "sync_with_goods",
          "goods_id" => unlockable_game.id,
          "goods_type" => "Unlockable",
          "auto_fulfill" => true
        }
      })

      {:ok, %{ data: price }} = Catalogue.create_price(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "product_id" => product_game.id },
        fields: %{
          "status" => "active",
          "name" => "Regular",
          "charge_amount_cents" => 499,
          "charge_unit" => "EA"
        }
      })

      {:ok, _} = Catalogue.update_price(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => price.id },
        fields: %{
          "name" => "原价",
          "charge_unit" => "个"
        },
        locale: "zh-CN"
      })

      {:ok, %{ data: price }} = Catalogue.create_price(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "product_id" => product_game.id },
        fields: %{
          "status" => "internal",
          "name" => "Influencer",
          "charge_amount_cents" => 399,
          "charge_unit" => "EA"
        }
      })

      {:ok, _} = Catalogue.update_price(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => price.id },
        fields: %{
          "name" => "网红价",
          "charge_unit" => "个"
        },
        locale: "zh-CN"
      })

      {:ok, _} = Catalogue.update_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => product_game.id },
        fields: %{
          "status" => "active"
        }
      })

      #
      # MARK: Shirt
      #
      {:ok, %{ data: stockable_shirt_s }} = Goods.create_stockable(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "code" => "MSHIRT-S",
          "status" => "active",
          "name" => "Men's Shirt - Size S",
          "unit_of_measure" => "EA"
        }
      })

      {:ok, _} = Goods.update_stockable(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => stockable_shirt_s.id },
        fields: %{
          "name" => "男士衬衫 - 小号",
          "unit_of_measure" => "件"
        },
        locale: "zh-CN"
      })

      {:ok, %{ data: stockable_shirt_m }} = Goods.create_stockable(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "code" => "MSHIRT-M",
          "status" => "active",
          "name" => "Men's Shirt Size M",
          "unit_of_measure" => "EA"
        }
      })

      {:ok, _} = Goods.update_stockable(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => stockable_shirt_m.id },
        fields: %{
          "name" => "男士衬衫 - 中号",
          "unit_of_measure" => "件"
        },
        locale: "zh-CN"
      })

      {:ok, %{ data: stockable_shirt_l }} = Goods.create_stockable(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "code" => "MSHIRT-L",
          "status" => "active",
          "name" => "Men's Shirt Size L",
          "unit_of_measure" => "EA"
        }
      })

      {:ok, _} = Goods.update_stockable(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => stockable_shirt_l.id },
        fields: %{
          "name" => "男士衬衫 - 大号",
          "unit_of_measure" => "件"
        },
        locale: "zh-CN"
      })

      {:ok, %{ data: product_shirt }} = Catalogue.create_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "code" => "MSHIRT",
          "kind" => "with_variants",
          "name" => "Men's Shirt"
        }
      })

      {:ok, _} = Catalogue.update_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => product_shirt.id },
        fields: %{
          "name" => "男士衬衫"
        },
        locale: "zh-CN"
      })

      {:ok, %{ data: product_shirt_s }} = Catalogue.create_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "code" => "MSHIRT-S",
          "kind" => "variant",
          "parent_id" => product_shirt.id,
          "name_sync" => "sync_with_goods",
          "short_name" => "Size S",
          "goods_id" => stockable_shirt_s.id,
          "goods_type" => "Stockable",
        }
      })

      {:ok, _} = Catalogue.update_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => product_shirt_s.id },
        fields: %{
          "short_name" => "小号"
        },
        locale: "zh-CN"
      })

      {:ok, %{ data: price }} = Catalogue.create_price(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "product_id" => product_shirt_s.id },
        fields: %{
          "status" => "active",
          "name" => "Regular",
          "charge_amount_cents" => 3999,
          "charge_unit" => "EA"
        }
      })

      {:ok, _} = Catalogue.update_price(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => price.id },
        fields: %{
          "name" => "原价",
          "charge_unit" => "件"
        },
        locale: "zh-CN"
      })

      {:ok, _} = Catalogue.update_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => product_shirt_s.id },
        fields: %{
          "status" => "active"
        }
      })

      {:ok, %{ data: product_shirt_m }} = Catalogue.create_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "code" => "MSHIRT-M",
          "kind" => "variant",
          "parent_id" => product_shirt.id,
          "primary" => true,
          "name_sync" => "sync_with_goods",
          "short_name" => "Size M",
          "goods_id" => stockable_shirt_m.id,
          "goods_type" => "Stockable",
        }
      })

      {:ok, _} = Catalogue.update_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => product_shirt_m.id },
        fields: %{
          "short_name" => "中号"
        },
        locale: "zh-CN"
      })

      {:ok, %{ data: price }} = Catalogue.create_price(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "product_id" => product_shirt_m.id },
        fields: %{
          "status" => "active",
          "name" => "Regular",
          "charge_amount_cents" => 3999,
          "charge_unit" => "EA"
        }
      })

      {:ok, _} = Catalogue.update_price(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => price.id },
        fields: %{
          "name" => "原价",
           "charge_unit" => "件"
        },
        locale: "zh-CN"
      })

      {:ok, _} = Catalogue.update_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => product_shirt_m.id },
        fields: %{
          "status" => "active"
        }
      })

      {:ok, %{ data: product_shirt_l }} = Catalogue.create_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "code" => "MSHIRT-L",
          "kind" => "variant",
          "parent_id" => product_shirt.id,
          "name_sync" => "sync_with_goods",
          "short_name" => "Size L",
          "goods_id" => stockable_shirt_l.id,
          "goods_type" => "Stockable",
        }
      })

      {:ok, _} = Catalogue.update_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => product_shirt_l.id },
        fields: %{
          "short_name" => "大号"
        },
        locale: "zh-CN"
      })

      {:ok, %{ data: price }} = Catalogue.create_price(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "product_id" => product_shirt_l.id },
        fields: %{
          "status" => "active",
          "name" => "Regular",
          "charge_amount_cents" => 3999,
          "charge_unit" => "EA"
        }
      })

      {:ok, _} = Catalogue.update_price(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => price.id },
        fields: %{
          "name" => "原价",
           "charge_unit" => "件"
        },
        locale: "zh-CN"
      })

      {:ok, _} = Catalogue.update_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => product_shirt_l.id },
        fields: %{
          "status" => "active"
        }
      })

      {:ok, _} = Catalogue.update_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => product_shirt.id },
        fields: %{
          "status" => "active"
        }
      })

      #
      # MARK: Salmon
      #
      {:ok, %{ data: stockable_salmon }} = Goods.create_stockable(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "code" => "SALMON",
          "status" => "active",
          "name" => "Salmon Fillet",
          "unit_of_measure" => "EA"
        }
      })

      {:ok, _} = Goods.update_stockable(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => stockable_salmon.id },
        fields: %{
          "name" => "三文鱼柳",
          "unit_of_measure" => "块"
        },
        locale: "zh-CN"
      })

      {:ok, %{ data: product_salmon }} = Catalogue.create_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "code" => "SALMON",
          "name_sync" => "sync_with_goods",
          "goods_id" => stockable_salmon.id,
          "goods_type" => "Stockable",
        }
      })

      {:ok, %{ data: price }} = Catalogue.create_price(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "product_id" => product_salmon.id },
        fields: %{
          "status" => "active",
          "name" => "Retail",
          "charge_amount_cents" => 1299,
          "charge_unit" => "LB",
          "order_unit" => "EA",
          "estimate_by_default" => true,
          "estimate_average_percentage" => 200,
          "estimate_maximum_percentage" => 300
        }
      })

      {:ok, _} = Catalogue.update_price(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => price.id },
        fields: %{
          "name" => "零售价",
          "charge_unit" => "磅",
          "order_unit" => "块"
        },
        locale: "zh-CN"
      })

      {:ok, %{ data: price }} = Catalogue.create_price(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "product_id" => product_salmon.id },
        fields: %{
          "status" => "active",
          "name" => "Wholesale",
          "minimum_order_quantity" => 10,
          "charge_amount_cents" => 1099,
          "charge_unit" => "LB",
          "order_unit" => "EA",
          "estimate_by_default" => true,
          "estimate_average_percentage" => 200,
          "estimate_maximum_percentage" => 300
        }
      })

      {:ok, _} = Catalogue.update_price(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => price.id },
        fields: %{
          "name" => "批发价",
          "charge_unit" => "磅",
          "order_unit" => "块"
        },
        locale: "zh-CN"
      })

      {:ok, _} = Catalogue.update_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => product_salmon.id },
        fields: %{
          "status" => "active"
        }
      })

      #
      # MARK: Fruit Combo
      #
      {:ok, %{ data: stockable_apple }} = Goods.create_stockable(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "code" => "APL",
          "status" => "active",
          "name" => "Apple",
          "unit_of_measure" => "EA"
        }
      })

      {:ok, _} = Goods.update_stockable(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => stockable_apple.id },
        fields: %{
          "name" => "苹果",
          "unit_of_measure" => "个"
        },
        locale: "zh-CN"
      })

      {:ok, %{ data: stockable_orange }} = Goods.create_stockable(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "code" => "ORG",
          "status" => "active",
          "name" => "Orange",
          "unit_of_measure" => "EA"
        }
      })

      {:ok, _} = Goods.update_stockable(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => stockable_orange.id },
        fields: %{
          "name" => "橙子",
          "unit_of_measure" => "个"
        },
        locale: "zh-CN"
      })

      {:ok, %{ data: product_fruit_combo }} = Catalogue.create_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "code" => "FUTCOMBO",
          "kind" => "combo",
          "name" => "Fruit Combo"
        }
      })

      {:ok, _} = Catalogue.update_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => product_fruit_combo.id },
        fields: %{
          "name" => "水果套餐"
        },
        locale: "zh-CN"
      })

      {:ok, %{ data: price }} = Catalogue.create_price(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "product_id" => product_fruit_combo.id },
        fields: %{
          "status" => "active",
          "name" => "Regular",
          "charge_unit" => "BOX",
          "charge_amount_cents" => "1097"
        }
      })

      {:ok, _} = Catalogue.update_price(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => price.id },
        fields: %{
          "name" => "原价",
          "charge_unit" => "盒"
        },
        locale: "zh-CN"
      })

      {:ok, _} = Catalogue.create_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "code" => "APL",
          "status" => "active",
          "kind" => "item",
          "price_proportion_index" => 30,
          "parent_id" => product_fruit_combo.id,
          "name_sync" => "sync_with_goods",
          "goods_id" => stockable_apple.id,
          "goods_type" => "Stockable",
        }
      })

      {:ok, _} = Catalogue.create_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "code" => "ORG",
          "status" => "active",
          "kind" => "item",
          "price_proportion_index" => 70,
          "parent_id" => product_fruit_combo.id,
          "name_sync" => "sync_with_goods",
          "goods_id" => stockable_orange.id,
          "goods_type" => "Stockable",
        }
      })

      {:ok, _} = Catalogue.update_product(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => product_fruit_combo.id },
        fields: %{
          "status" => "active"
        }
      })

      {:ok, %{ data: collection_food }} = Catalogue.create_product_collection(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "status" => "active",
          "name" => "Food",
          "code" => "FD",
          "sort_index" => 800
        }
      })

      {:ok, _} = Catalogue.update_product_collection(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        params: %{ "id" => collection_food.id },
        fields: %{
          "name" => "食品"
        },
        locale: "zh-CN"
      })

      {:ok, _} = Catalogue.create_product_collection_membership(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "collection_id" => collection_food.id,
          "product_id" => product_salmon.id,
          "sort_index" => 900
        }
      })

      {:ok, _} = Catalogue.create_product_collection_membership(%AccessRequest{
        vas: %{ user_id: user.id, account_id: test_account.id },
        fields: %{
          "collection_id" => collection_food.id,
          "product_id" => product_fruit_combo.id,
          "sort_index" => 1000
        }
      })
    end)
  end
end