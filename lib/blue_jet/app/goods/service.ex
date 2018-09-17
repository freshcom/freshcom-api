defmodule BlueJet.Goods.Service do
  use BlueJet, :service

  alias BlueJet.Goods.{Stockable, Unlockable, Depositable}

  def list_stockable(query \\ %{}, opts), do: default(:list, Stockable, query, opts)
  def count_stockable(query \\ %{}, opts), do: default(:count, Stockable, query, opts)
  def create_stockable(fields, opts), do: default(:create, Stockable, fields, opts)
  def get_stockable(identifiers, opts), do: default(:get, Stockable, identifiers, opts)
  def update_stockable(identifiers, fields, opts), do: default(:update, identifiers, fields, opts, &get_stockable/2)
  def delete_stockable(identifiers, opts), do: default(:delete, identifiers, opts, &get_stockable/2)
  def delete_all_stockable(opts), do: default(:delete_all, Stockable, opts)

  #
  # MARK: Unlockable
  #
  def list_unlockable(query \\ %{}, opts), do: default(:list, Unlockable, query, opts)
  def count_unlockable(query \\ %{}, opts), do: default(:count, Unlockable, query, opts)
  def create_unlockable(fields, opts), do: default(:create, Unlockable, fields, opts)
  def get_unlockable(identifiers, opts), do: default(:get, Unlockable, identifiers, opts)
  def update_unlockable(identifiers, fields, opts), do: default(:update, identifiers, fields, opts, &get_unlockable/2)
  def delete_unlockable(identifiers, opts), do: default(:delete, identifiers, opts, &get_unlockable/2)
  def delete_all_unlockable(opts), do: default(:delete_all, Unlockable, opts)

  #
  # MARK: Depositable
  #
  def list_depositable(query \\ %{}, opts), do: default(:list, Depositable, query, opts)
  def count_depositable(query \\ %{}, opts), do: default(:count, Depositable, query, opts)
  def create_depositable(fields, opts), do: default(:create, Depositable, fields, opts)
  def get_depositable(identifiers, opts), do: default(:get, Depositable, identifiers, opts)
  def update_depositable(identifiers, fields, opts), do: default(:update, identifiers, fields, opts, &get_depositable/2)
  def delete_depositable(identifiers, opts), do: default(:delete, identifiers, opts, &get_depositable/2)
  def delete_all_depositable(opts), do: default(:delete_all, Depositable, opts)
end