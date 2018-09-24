defmodule BlueJet.Goods.Service do
  use BlueJet, :service

  alias BlueJet.Goods.{Stockable, Unlockable, Depositable}

  def list_stockable(query \\ %{}, opts), do: default_list(Stockable.Query, query, opts)
  def count_stockable(query \\ %{}, opts), do: default_count(Stockable.Query, query, opts)
  def create_stockable(fields, opts), do: default_create(Stockable, fields, opts)
  def get_stockable(identifiers, opts), do: default_get(Stockable.Query, identifiers, opts)
  def update_stockable(%Stockable{} = stockable, fields, opts), do: default_update(stockable, fields, opts)
  def update_stockable(identifiers, fields, opts), do: default_update(identifiers, fields, opts, &get_stockable/2)
  def delete_stockable(%Stockable{} = stockable, opts), do: default_delete(stockable, opts)
  def delete_stockable(identifiers, opts), do: default_delete(identifiers, opts, &get_stockable/2)
  def delete_all_stockable(opts), do: default_delete_all(Stockable.Query, opts)

  #
  # MARK: Unlockable
  #
  def list_unlockable(query \\ %{}, opts), do: default_list(Unlockable.Query, query, opts)
  def count_unlockable(query \\ %{}, opts), do: default_count(Unlockable.Query, query, opts)
  def create_unlockable(fields, opts), do: default_create(Unlockable, fields, opts)
  def get_unlockable(identifiers, opts), do: default_get(Unlockable.Query, identifiers, opts)
  def update_unlockable(%Unlockable{} = unlockable, fields, opts), do: default_update(unlockable, fields, opts)
  def update_unlockable(identifiers, fields, opts), do: default_update(identifiers, fields, opts, &get_unlockable/2)
  def delete_unlockable(%Unlockable{} = unlockable, opts), do: default_delete(unlockable, opts)
  def delete_unlockable(identifiers, opts), do: default_delete(identifiers, opts, &get_unlockable/2)
  def delete_all_unlockable(opts), do: default_delete_all(Unlockable.Query, opts)

  #
  # MARK: Depositable
  #
  def list_depositable(query \\ %{}, opts), do: default_list(Depositable.Query, query, opts)
  def count_depositable(query \\ %{}, opts), do: default_count(Depositable.Query, query, opts)
  def create_depositable(fields, opts), do: default_create(Depositable, fields, opts)
  def get_depositable(identifiers, opts), do: default_get(Depositable.Query, identifiers, opts)
  def update_depositable(%Depositable{} = depositable, fields, opts), do: default_update(depositable, fields, opts)
  def update_depositable(identifiers, fields, opts), do: default_update(identifiers, fields, opts, &get_depositable/2)
  def delete_depositable(%Depositable{} = depositable, opts), do: default_delete(depositable, opts)
  def delete_depositable(identifiers, opts), do: default_delete(identifiers, opts, &get_depositable/2)
  def delete_all_depositable(opts), do: default_delete_all(Depositable.Query, opts)
end