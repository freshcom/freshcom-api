defmodule BlueJet.Goods.DefaultService do
  use BlueJet, :service

  alias BlueJet.Goods.{Stockable, Unlockable, Depositable}

  @behaviour BlueJet.Goods.Service

  def list_stockable(fields \\ %{}, opts) do
    list(Stockable, fields, opts)
  end

  def count_stockable(fields \\ %{}, opts) do
    count(Stockable, fields, opts)
  end

  def create_stockable(fields, opts) do
    create(Stockable, fields, opts)
  end

  def get_stockable(identifiers, opts) do
    get(Stockable, identifiers, opts)
  end

  def update_stockable(nil, _, _), do: {:error, :not_found}

  def update_stockable(stockable = %Stockable{}, fields, opts) do
    update(stockable, fields, opts)
  end

  def update_stockable(identifiers, fields, opts) do
    get_stockable(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> update_stockable(fields, opts)
  end

  def delete_stockable(nil, _), do: {:error, :not_found}

  def delete_stockable(stockable = %Stockable{}, opts) do
    delete(stockable, opts)
  end

  def delete_stockable(identifiers, opts) do
    get_stockable(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> delete_stockable(opts)
  end

  def delete_all_stockable(opts)  do
    delete_all(Stockable, opts)
  end

  #
  # MARK: Unlockable
  #
  def list_unlockable(fields \\ %{}, opts) do
    list(Unlockable, fields, opts)
  end

  def count_unlockable(fields \\ %{}, opts) do
    count(Unlockable, fields, opts)
  end

  def create_unlockable(fields, opts) do
    create(Unlockable, fields, opts)
  end

  def get_unlockable(identifiers, opts) do
    get(Unlockable, identifiers, opts)
  end

  def update_unlockable(nil, _, _), do: {:error, :not_found}

  def update_unlockable(unlockable = %Unlockable{}, fields, opts) do
    update(unlockable, fields, opts)
  end

  def update_unlockable(identifiers, fields, opts) do
    get_unlockable(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> update_unlockable(fields, opts)
  end

  def delete_unlockable(nil, _), do: {:error, :not_found}

  def delete_unlockable(unlockable = %Unlockable{}, opts) do
    delete(unlockable, opts)
  end

  def delete_unlockable(identifiers, opts) do
    get_unlockable(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> delete_unlockable(opts)
  end

  def delete_all_unlockable(opts)  do
    delete_all(Unlockable, opts)
  end

  #
  # MARK: Depositable
  #
  def list_depositable(fields \\ %{}, opts) do
    list(Depositable, fields, opts)
  end

  def count_depositable(fields \\ %{}, opts) do
    count(Depositable, fields, opts)
  end

  def create_depositable(fields, opts) do
    create(Depositable, fields, opts)
  end

  def get_depositable(identifiers, opts) do
    get(Depositable, identifiers, opts)
  end

  def update_depositable(nil, _, _), do: {:error, :not_found}

  def update_depositable(depositable = %Depositable{}, fields, opts) do
    update(depositable, fields, opts)
  end

  def update_depositable(identifiers, fields, opts) do
    get_depositable(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> update_depositable(fields, opts)
  end

  def delete_depositable(nil, _), do: {:error, :not_found}

  def delete_depositable(depositable = %Depositable{}, opts) do
    delete(depositable, opts)
  end

  def delete_depositable(identifiers, opts) do
    get_depositable(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> delete_depositable(opts)
  end

  def delete_all_depositable(opts)  do
    delete_all(Depositable, opts)
  end
end