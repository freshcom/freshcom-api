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
    alias BlueJet.AccessRequest

    ensure_started(Repo, [])

    {:ok, %{ data: user }} = Identity.create_user(%AccessRequest{
      fields: %{
        "first_name" => "Roy",
        "last_name" => "Bao",
        "username" => "roy@freshcom.io",
        "email" => "roy@freshcom.io",
        "password" => "test1234",
        "account_name" => "Hines Education",
        "default_locale" => "zh-CN"
      }
    })

    account = Repo.get_by(Account, id: user.default_account_id)
    test_account = Repo.get_by(Account, mode: "test", live_account_id: account.id)

    {:ok, _} = Catalogue.create_product_collection(%AccessRequest{
      vas: %{ user_id: user.id, account_id: test_account.id },
      fields: %{
        "name" => "本月推荐（TOM）",
        "code" => "TOM",
        "label" => "audio",
        "sort_index" => 1000
      }
    })

    {:ok, _} = Catalogue.create_product_collection(%AccessRequest{
      vas: %{ user_id: user.id, account_id: test_account.id },
      fields: %{
        "name" => "经销商培训CD",
        "code" => "ASSOC-TR-AUD",
        "label" => "audio",
        "sort_index" => 900
      }
    })

    {:ok, _} = Catalogue.create_product_collection(%AccessRequest{
      vas: %{ user_id: user.id, account_id: test_account.id },
      fields: %{
        "name" => "领导力培训CD",
        "code" => "LDR-TR-AUD",
        "label" => "audio",
        "sort_index" => 800
      }
    })

    {:ok, _} = Catalogue.create_product_collection(%AccessRequest{
      vas: %{ user_id: user.id, account_id: test_account.id },
      fields: %{
        "name" => "充值",
        "code" => "DEPOSIT",
        "label" => "deposit"
      }
    })
  end
end