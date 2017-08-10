defmodule BlueJet.Identity do
  use BlueJet, :context

  alias BlueJet.Identity.Authentication
  alias BlueJet.Identity.Customer
  alias BlueJet.Identity.User
  alias BlueJet.Identity.RefreshToken
  alias BlueJet.Identity.AccountMembership
  alias BlueJet.Identity.Account

  def authenticate(args) do
    Authentication.get_token(args)
  end

  # Create new User to existing account
  def create_user(request = %{ vas: %{ account_id: account_id } }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)

    changeset = User.changeset(%User{}, request.fields)

    Repo.transaction(fn ->
      with {:ok, user} <- Repo.insert(changeset),
           {:ok, _refresh_token} <- RefreshToken.changeset(%RefreshToken{}, %{ user_id: user.id, account_id: account_id }) |> Repo.insert,
           {:ok, _membership} <- AccountMembership.changeset(%AccountMembership{}, %{ role: "admin", account_id: account_id, user_id: user.id }) |> Repo.insert
      do
        user
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end
  # Sign up a new User
  def create_user(request) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)

    Repo.transaction(fn ->
      with {:ok, default_account} <- Account.changeset(%Account{}, %{ name: Map.get(request.fields, "account_name") }) |> Repo.insert,
           {:ok, user} <- User.changeset(%User{}, Map.put(request.fields, "default_account_id", default_account.id)) |> Repo.insert,
           {:ok, _refresh_token} <- RefreshToken.changeset(%RefreshToken{}, %{ user_id: user.id, account_id: default_account.id }) |> Repo.insert,
           {:ok, _refresh_token} <- RefreshToken.changeset(%RefreshToken{}, %{ account_id: default_account.id }) |> Repo.insert,
           {:ok, _membership} <- AccountMembership.changeset(%AccountMembership{}, %{ role: "admin", account_id: default_account.id, user_id: user.id }) |> Repo.insert
      do
        user
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  ####
  # Customer
  ####
  def create_customer(request = %{ vas: vas }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)

    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })
    changeset = Customer.changeset(%Customer{}, fields)

    Repo.transaction(fn ->
      with {:ok, customer} <- Repo.insert(changeset),
           {:ok, _refresh_token} <- RefreshToken.changeset(%RefreshToken{}, %{ customer_id: customer.id, account_id: customer.account_id }) |> Repo.insert
      do
        Repo.preload(customer, request.preloads)
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  def get_customer!(request = %{ vas: vas, customer_id: customer_id }) do
    defaults = %{ locale: "en", preloads: [] }
    request = Map.merge(defaults, request)

    customer =
      Customer
      |> Repo.get_by!(account_id: vas[:account_id], id: customer_id)
      |> Repo.preload(request.preloads)
      |> Translation.translate(request.locale)

    customer
  end

  def update_customer(request = %{ vas: vas, customer_id: customer_id }) do
    defaults = %{ preloads: [], fields: %{}, locale: "en" }
    request = Map.merge(defaults, request)

    vas_customer_id = vas[:customer_id]
    customer =
      from(c in Customer, where: c.id == ^vas_customer_id)
      |> Repo.get_by!(account_id: vas[:account_id], id: customer_id)

    changeset = Customer.changeset(customer, request.fields, request.locale)

    with {:ok, customer} <- Repo.update(changeset) do
      customer =
        customer
        |> Repo.preload(request.preloads)
        |> Translation.translate(request.locale)

      {:ok, customer}
    else
      other -> other
    end
  end

  def list_customers(request = %{ vas: vas }) do
    defaults = %{ search_keyword: "", filter: %{}, page_size: 25, page_number: 1, locale: "en", preloads: [] }
    request = Map.merge(defaults, request)
    account_id = vas[:account_id]

    query =
      Customer
      |> search([:first_name, :last_name, :code, :email, :phone_number, :id], request.search_keyword, request.locale)
      |> filter_by(status: request.filter[:status], label: request.filter[:label], delivery_address_country_code: request.filter[:delivery_address_country_code])
      |> where([s], s.account_id == ^account_id)
    result_count = Repo.aggregate(query, :count, :id)

    total_query = Customer |> where([s], s.account_id == ^account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: request.page_size, number: request.page_number)

    customers =
      Repo.all(query)
      |> Repo.preload(request.preloads)
      |> Translation.translate(request.locale)

    %{
      total_count: total_count,
      result_count: result_count,
      customers: customers
    }
  end

  def delete_customer!(%{ vas: vas, customer_id: customer_id }) do
    customer = Repo.get_by!(Customer, account_id: vas[:account_id], id: customer_id)
    Repo.delete!(customer)
  end
end
