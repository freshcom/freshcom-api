defmodule BlueJet.Plugs.IncludeTest do
  use BlueJet.DataCase

  alias BlueJet.Plugs.Include

  describe "call/2" do
    test "with non nested include" do
      conn = %Plug.Conn{ query_params: %{ "include" => "avatar,fileCollections" } }
      conn = Include.call(conn, %{})

      assert conn.assigns[:preloads] == [:avatar, :file_collections]
    end

    test "with nested include" do
      conn = %Plug.Conn{ query_params: %{ "include" => "productItems.sku.avatar,avatar,fileCollections.files" } }
      conn = Include.call(conn, %{})

      assert conn.assigns[:preloads] == [:avatar, file_collections: :files, product_items: [sku: :avatar]]
    end

    test "with nested include and some same root key" do
      conn = %Plug.Conn{ query_params: %{ "include" => "productItems.sku.avatar,avatar,fileCollections.files,productItems.product" } }
      conn = Include.call(conn, %{})

      assert conn.assigns[:preloads] == [:avatar, file_collections: :files, product_items: [:product, {:sku, :avatar}]]
    end
  end
end
