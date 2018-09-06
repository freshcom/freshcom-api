defmodule Mix.Tasks.BlueJet.Db.Init do
  use Mix.Task
  import Mix.Ecto

  @shortdoc "Add initial account for alpha release"

  @moduledoc """
    This is where we would put any long form documentation or doctests.
  """

  def run(args) do
    alias BlueJet.Repo

    alias BlueJet.Identity
    alias BlueJet.Identity.Account

    alias BlueJet.Catalogue
    alias BlueJet.Goods
    alias BlueJet.ContextRequest

    Application.ensure_all_started(:blue_jet)
    # Application.ensure_all_started(:bamboo)

    {:ok, %{ data: user }} = Identity.create_user(%ContextRequest{
      fields: %{
        "first_name" => "Roy",
        "last_name" => "Bao",
        "username" => "roy@freshcom.io",
        "email" => "roy@freshcom.io",
        "password" => "test1234",
        "account_name" => "Example",
        "default_locale" => "zh-CN"
      }
    })

    account = Repo.get_by(Account, id: user.default_account_id)
    test_account = Repo.get_by(Account, mode: "test", live_account_id: account.id)

    {:ok, _} = Identity.update_account(%ContextRequest{
      vas: %{ user_id: user.id, account_id: account.id },
      account: account,
      fields: %{ default_auth_method: "tfa_sms" }
    })

    {:ok, _} = Catalogue.create_product_collection(%ContextRequest{
      vas: %{ user_id: user.id, account_id: test_account.id },
      fields: %{
        "status" => "active",
        "name" => "本月推荐（TOM）",
        "code" => "TOM",
        "label" => "audio",
        "sort_index" => 1000
      }
    })

    {:ok, _} = Catalogue.create_product_collection(%ContextRequest{
      vas: %{ user_id: user.id, account_id: test_account.id },
      fields: %{
        "status" => "active",
        "name" => "经销商培训CD",
        "code" => "ASSOC-TR-AUD",
        "label" => "audio",
        "sort_index" => 900
      }
    })

    {:ok, _} = Catalogue.create_product_collection(%ContextRequest{
      vas: %{ user_id: user.id, account_id: test_account.id },
      fields: %{
        "status" => "active",
        "name" => "领导力培训CD",
        "code" => "LDR-TR-AUD",
        "label" => "audio",
        "sort_index" => 800
      }
    })

    {:ok, _} = Catalogue.create_product_collection(%ContextRequest{
      vas: %{ user_id: user.id, account_id: test_account.id },
      fields: %{
        "status" => "active",
        "name" => "充值",
        "code" => "DEPOSIT",
        "label" => "deposit"
      }
    })

    #
    # MARK: Deposit
    #
    {:ok, %{ data: deposit_100 }} = Goods.create_depositable(%ContextRequest{
      vas: %{ user_id: user.id, account_id: test_account.id },
      fields: %{
        "status" => "active",
        "name" => "充值 CAD$100",
        "code" => "DEP100",
        "gateway" => "freshcom",
        "amount" => 10000
      }
    })

    {:ok, %{ data: product_100 }} = Catalogue.create_product(%ContextRequest{
      vas: %{ user_id: user.id, account_id: test_account.id },
      fields: %{
        "name_sync" => "sync_with_goods",
        "goods_id" => deposit_100.id,
        "goods_type" => "Depositable",
        "auto_fulfill" => true
      }
    })

    {:ok, _} = Catalogue.create_price(%ContextRequest{
      vas: %{ user_id: user.id, account_id: test_account.id },
      params: %{ "product_id" => product_100.id },
      fields: %{
        "status" => "active",
        "name" => "原价",
        "charge_amount_cents" => 10000,
        "charge_unit" => "个",
        "order_unit" => "个"
      }
    })

    {:ok, _} = Catalogue.update_product(%ContextRequest{
      vas: %{ user_id: user.id, account_id: test_account.id },
      params: %{ "id" => product_100.id },
      fields: %{
        "status" => "active"
      }
    })

    {:ok, %{ data: deposit_50 }} = Goods.create_depositable(%ContextRequest{
      vas: %{ user_id: user.id, account_id: test_account.id },
      fields: %{
        "status" => "active",
        "name" => "充值 CAD$50",
        "code" => "DEP50",
        "gateway" => "freshcom",
        "amount" => 5000
      }
    })

    {:ok, %{ data: product_50 }} = Catalogue.create_product(%ContextRequest{
      vas: %{ user_id: user.id, account_id: test_account.id },
      fields: %{
        "name_sync" => "sync_with_goods",
        "goods_id" => deposit_50.id,
        "goods_type" => "Depositable",
        "auto_fulfill" => true
      }
    })

    {:ok, _} = Catalogue.create_price(%ContextRequest{
      vas: %{ user_id: user.id, account_id: test_account.id },
      params: %{ "product_id" => product_50.id },
      fields: %{
        "status" => "active",
        "name" => "原价",
        "charge_amount_cents" => 5000,
        "charge_unit" => "个",
        "order_unit" => "个"
      }
    })

    {:ok, _} = Catalogue.update_product(%ContextRequest{
      vas: %{ user_id: user.id, account_id: test_account.id },
      params: %{ "id" => product_50.id },
      fields: %{
        "status" => "active"
      }
    })
  end
end