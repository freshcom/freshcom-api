defmodule BlueJet.CrmTest do
  use BlueJet.ContextCase

  alias BlueJet.Identity.{Account, User}
  alias BlueJet.Crm
  alias BlueJet.Crm.{Customer, PointAccount, PointTransaction}
  alias BlueJet.Crm.IdentityServiceMock

  setup :verify_on_exit!

  describe "list_customer/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Crm.list_customer(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = Repo.insert!(%Account{})
      Repo.insert!(%Customer{
        account_id: account.id,
        name: Faker.String.base64(5)
      })

      request = %AccessRequest{
        role: "developer",
        account: account
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Crm.list_customer(request)
      assert length(response.data) == 1
      assert response.meta.all_count == 1
      assert response.meta.total_count == 1
    end
  end

  describe "create_customer/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Crm.create_customer(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = Repo.insert!(%Account{})
      user = Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        username: Faker.Internet.email()
      })

      IdentityServiceMock
      |> expect(:create_user, fn(_) -> {:ok, user} end)

      request = %AccessRequest{
        role: "developer",
        account: account,
        fields: %{
          "status" => "registered",
          "name" => Faker.String.base64(5),
          "email" => Faker.Internet.email()
        }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Crm.create_customer(request)

      customer = Repo.get_by(Customer, user_id: user.id)
      assert response.data.id == customer.id
    end
  end

  describe "get_customer/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Crm.get_customer(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = Repo.insert!(%Account{})
      customer = Repo.insert!(%Customer{
        account_id: account.id,
        name: Faker.String.base64(5)
      })

      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "id" => customer.id }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Crm.get_customer(request)

      assert response.data.id == customer.id
    end
  end

  describe "update_customer/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Crm.update_customer(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = Repo.insert!(%Account{})
      user = Repo.insert!(%User{
        account_id: account.id,
        default_account_id: account.id,
        username: Faker.Internet.email()
      })
      customer = Repo.insert!(%Customer{
        account_id: account.id,
        name: Faker.String.base64(5),
        email: Faker.Internet.email()
      })

      IdentityServiceMock
      |> expect(:create_user, fn(_) -> {:ok, user} end)

      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "id" => customer.id },
        fields: %{ "status" => "registered" }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Crm.update_customer(request)

      assert response.data.id == customer.id
    end
  end

  describe "delete_customer/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Crm.delete_customer(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = Repo.insert!(%Account{})
      customer = Repo.insert!(%Customer{
        account_id: account.id,
        name: Faker.String.base64(5)
      })

      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "id" => customer.id }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, _} = Crm.delete_customer(request)
    end
  end

  describe "list_point_transaction/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Crm.list_point_transaction(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = Repo.insert!(%Account{})
      customer = Repo.insert!(%Customer{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      point_account = Repo.insert!(%PointAccount{
        account_id: account.id,
        customer_id: customer.id
      })
      Repo.insert!(%PointTransaction{
        account_id: account.id,
        point_account_id: point_account.id,
        amount: 5000
      })
      Repo.insert!(%PointTransaction{
        account_id: account.id,
        point_account_id: point_account.id,
        status: "committed",
        amount: 5000
      })

      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "point_account_id" => point_account.id }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Crm.list_point_transaction(request)
      assert length(response.data) == 1
    end
  end

  describe "create_point_transaction/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Crm.create_point_transaction(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = Repo.insert!(%Account{})
      customer = Repo.insert!(%Customer{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      point_account = Repo.insert!(%PointAccount{
        account_id: account.id,
        customer_id: customer.id
      })

      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "point_account_id" => point_account.id },
        fields: %{ "amount" => 5000 }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Crm.create_point_transaction(request)
      assert response.data
    end
  end

  describe "get_point_transaction/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Crm.get_point_transaction(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = Repo.insert!(%Account{})
      customer = Repo.insert!(%Customer{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      point_account = Repo.insert!(%PointAccount{
        account_id: account.id,
        customer_id: customer.id
      })
      point_transaction = Repo.insert!(%PointTransaction{
        account_id: account.id,
        point_account_id: point_account.id,
        amount: 5000
      })

      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "id" => point_transaction.id }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Crm.get_point_transaction(request)
      assert response.data.id == point_transaction.id
    end
  end

  describe "update_point_transaction/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Crm.update_point_transaction(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = Repo.insert!(%Account{})
      customer = Repo.insert!(%Customer{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      point_account = Repo.insert!(%PointAccount{
        account_id: account.id,
        customer_id: customer.id
      })
      point_transaction = Repo.insert!(%PointTransaction{
        account_id: account.id,
        point_account_id: point_account.id,
        amount: 5000
      })

      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "id" => point_transaction.id },
        fields: %{ "name" => Faker.String.base64(5) }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, response} = Crm.update_point_transaction(request)
      assert response.data.id == point_transaction.id
    end
  end

  describe "delete_point_transaction/1" do
    test "when role is not authorized" do
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:error, :access_denied} end)

      {:error, error} = Crm.delete_point_transaction(%AccessRequest{})
      assert error == :access_denied
    end

    test "when request is valid" do
      account = Repo.insert!(%Account{})
      customer = Repo.insert!(%Customer{
        account_id: account.id,
        name: Faker.String.base64(5)
      })
      point_account = Repo.insert!(%PointAccount{
        account_id: account.id,
        customer_id: customer.id
      })
      point_transaction = Repo.insert!(%PointTransaction{
        account_id: account.id,
        point_account_id: point_account.id,
        amount: 0
      })

      request = %AccessRequest{
        role: "developer",
        account: account,
        params: %{ "id" => point_transaction.id }
      }
      AuthorizationMock
      |> expect(:authorize_request, fn(_, _) -> {:ok, request} end)

      {:ok, _} = Crm.delete_point_transaction(request)
    end
  end
end
