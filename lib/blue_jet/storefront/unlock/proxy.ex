defmodule BlueJet.Storefront.Unlock.Proxy do
  use BlueJet, :proxy

  alias BlueJet.Storefront.{GoodsService, CrmService}

  def put(order, {:customer, customer_path}, opts) do
    preloads = %{ path: customer_path, opts: opts }
    opts =
      opts
      |> Map.take([:account, :account_id])
      |> Map.merge(%{ preloads: preloads })

    customer = CrmService.get_customer(%{ id: order.customer_id }, opts)
    %{ order | customer: customer }
  end

  def put(order, {:unlockable, unlockable_path}, opts) do
    preloads = %{ path: unlockable_path, opts: opts }
    opts =
      opts
      |> Map.take([:account, :account_id])
      |> Map.merge(%{ preloads: preloads })

    unlockable = GoodsService.get_unlockable(%{ id: order.unlockable_id }, opts)
    %{ order | unlockable: unlockable }
  end

  def put(unlock, _, _), do: unlock
end