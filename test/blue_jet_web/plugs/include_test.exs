defmodule BlueJet.Plugs.IncludeTest do
  use BlueJet.DataCase, async: true

  alias BlueJet.Plugs.Include

  describe "call/2" do
    test "with non nested include" do
      conn = %Plug.Conn{ query_params: %{ "include" => "avatar,externalFileCollections" } }
      conn = Include.call(conn, %{})

      assert conn.assigns[:preloads] == [:avatar, :external_file_collections]
    end

    test "with nested include" do
      conn = %Plug.Conn{ query_params: %{ "include" => "productItems.sku.avatar,avatar,externalFileCollections.files" } }
      conn = Include.call(conn, %{})

      assert conn.assigns[:preloads] == [:avatar, external_file_collections: :files, product_items: [sku: :avatar]]
    end
  end
end
