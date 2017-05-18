# defmodule BlueJet.RefreshTokenControllerTest do
#   use BlueJet.ConnCase

#   alias BlueJet.UserRegistration
#   alias BlueJet.RefreshToken
#   alias BlueJet.Repo

#   @valid_attrs %{name: "some content", system_tag: "some content", value: "some content"}
#   @invalid_attrs %{}

#   setup do
#     conn = build_conn()
#       |> put_req_header("accept", "application/vnd.api+json")
#       |> put_req_header("content-type", "application/vnd.api+json")

#     {:ok, conn: conn}
#   end

#   describe "POST /jwts" do
#     test "with valid attrs", %{conn: conn} do
#       valid_attrs = %{ "email" => "test1@example.com", "password" => "test1234" }
#       UserRegistration.sign_up(%{
#         first_name: Faker.Name.first_name,
#         last_name: Faker.Name.last_name,
#         email: Map.get(valid_attrs, "email"),
#         password: Map.get(valid_attrs, "password"),
#         account_name: "Outersky"
#       })

#       conn = post(conn, jwt_path(conn, :create), %{
#         "data" => %{
#           "type" => "RefreshToken",
#           "attributes" => valid_attrs
#         }
#       })

#       assert json_response(conn, 201)["data"]["id"]
#     end

#     test "with invalid attrs", %{conn: conn} do
#       valid_attrs = %{ email: "test1@example.com", password: "test1234" }
#       UserRegistration.sign_up(%{
#         first_name: Faker.Name.first_name,
#         last_name: Faker.Name.last_name,
#         email: "test1@example.com",
#         password: "test1234",
#         account_name: "Outersky"
#       })

#       conn = post(conn, jwt_path(conn, :create), %{
#         "data" => %{
#           "type" => "RefreshToken",
#           "attributes" => %{ "email" => "invalid", "password" => "invalid" }
#         }
#       })

#       assert length(json_response(conn, 422)["errors"]) > 0
#     end
#   end
# end
