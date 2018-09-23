# defmodule BlueJetWeb.OrderControllerTest do
#   use BlueJetWeb.ConnCase

#   import BlueJet.Identity.TestHelper

#   setup do
#     conn =
#       build_conn()
#       |> put_req_header("accept", "application/vnd.api+json")
#       |> put_req_header("content-type", "application/vnd.api+json")

#     %{conn: conn}
#   end

#   # Create an order
#   describe "POST /v1/orders" do
#     test "without PAT", %{conn: conn} do
#       conn = get(conn, "/v1/users")

#       assert conn.status == 401
#     end

#     test "with no attributes", %{conn: conn} do
#       conn = post(conn, "/v1/orders", %{
#         "data" => %{
#           "type" => "Order"
#         }
#       })

#       response = json_response(conn, 422)
#       assert length(response["errors"]) == 3
#     end
#   end

#   # Retrieve an order
#   describe "GET /v1/orders/:id" do
#     test "without PAT", %{conn: conn} do
#       conn = get(conn, "/v1/orders/#{Ecto.UUID.generate()}")

#       assert conn.status == 401
#     end
#   end

#   # Update an order
#   describe "PATCH /v1/orders/:id" do
#     test "without PAT", %{conn: conn} do
#       conn = get(conn, "/v1/orders/#{Ecto.UUID.generate()}")

#       assert conn.status == 401
#     end
#   end

#   # Delete an order
#   describe "DELETE /v1/orders/:id" do
#     test "without PAT", %{conn: conn} do
#     end
#   end

#   # List order
#   describe "GET /v1/orders" do
#     test "without UAT", %{conn: conn} do
#       conn = get(conn, "/v1/orders")

#       assert conn.status == 401
#     end
#   end
# end
