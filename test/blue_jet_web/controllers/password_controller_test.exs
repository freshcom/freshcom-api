defmodule BlueJetWeb.PasswordControllerTest do
  use BlueJetWeb.ConnCase

  alias BlueJet.AccessRequest
  alias BlueJet.Identity
  alias BlueJet.Identity.RefreshToken

  def create_standard_user() do
    Identity.create_user(%AccessRequest{
      fields: %{
        "name" => Faker.Name.name(),
        "username" => "standard_user1@example.com",
        "email" => "standard_user1@example.com",
        "password" => "standard1234",
        "default_locale" => "en"
      }
    })
  end

  setup do
    conn =
      build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    %{conn: conn}
  end

  describe "PATCH /v1/password" do
    test "given invalid password reset token", %{conn: conn} do
      conn = patch(conn, "/v1/password", %{
        "data" => %{
          "type" => "Password",
          "attributes" => %{
            "resetToken" => "invalid"
          }
        }
      })

      response = json_response(conn, 422)
      assert length(response["errors"]) == 1
    end
  end
end
