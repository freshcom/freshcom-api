defmodule BlueJet.ProductItemView do
  use BlueJet.Web, :view
  use JaSerializer.PhoenixView

  attributes [:code, :status, :sort_index, :quantity, :maximum_order_quantity, :primary, :print_name, :inserted_at, :updated_at]
  

end
