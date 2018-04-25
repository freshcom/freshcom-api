defmodule BlueJet.Balance do
  use BlueJet, :context
  use BlueJet.EventEmitter, namespace: :balance

  alias BlueJet.Balance.{Policy, Service}

  #
  # MARK: Settings
  #
  def get_settings(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "get_settings") do
      do_get_settings(authorize_args)
    else
      other -> other
    end
  end

  def do_get_settings(args) do
    settings = Service.get_settings(args[:opts])

    if settings do
      {:ok, %AccessResponse{ meta: %{ locale: args[:opts][:locale] }, data: settings }}
    else
      {:error, :not_found}
    end
  end

  def update_settings(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "update_settings") do
      do_update_settings(authorize_args)
    else
      other -> other
    end
  end

  def do_update_settings(args) do
    with {:ok, settings} <- Service.update_settings(args[:fields], args[:opts]) do
      {:ok, %AccessResponse{ meta: %{ locale: args[:opts][:locale] }, data: settings }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # MARK: Card
  #
  def list_card(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "list_card") do
      do_list_card(authorize_args)
    else
      other -> other
    end
  end

  def do_list_card(args) do
    total_count =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.count_card(args[:opts])

    all_count =
      %{ filter: args[:all_count_filter] }
      |> Service.count_card(args[:opts])

    cards =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.list_card(args[:opts])
      |> Translation.translate(args[:opts][:locale], args[:opts][:account].default_locale)

    response = %AccessResponse{
      meta: %{
        locale: args[:opts][:locale],
        all_count: all_count,
        total_count: total_count,
      },
      data: cards
    }

    {:ok, response}
  end

  def update_card(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "update_card") do
      do_update_card(authorize_args)
    else
      other -> other
    end
  end

  def do_update_card(args) do
    with {:ok, card} <- Service.update_card(args[:id], args[:fields], args[:opts]) do
      card = Translation.translate(card, args[:opts][:locale], args[:opts][:account].default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: args[:opts][:locale] }, data: card }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_card(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "delete_card") do
      do_delete_card(authorize_args)
    else
      other -> other
    end
  end

  def do_delete_card(args) do
    with {:ok, _} <- Service.delete_card(args[:id], args[:opts]) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # MARK: Payment
  #
  def list_payment(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "list_payment") do
      do_list_payment(authorize_args)
    else
      other -> other
    end
  end

  def do_list_payment(args = %{ opts: %{ account: account } }) do
    total_count =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.count_payment(args[:opts])

    all_count = Service.count_payment(%{ filter: args[:filter] }, %{ account: args[:opts][:account] })

    payments =
      %{ filter: args[:filter], search: args[:search] }
      |> Service.list_payment(args[:opts])
      |> Translation.translate(args[:opts][:locale], account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: args[:opts][:locale],
        all_count: all_count,
        total_count: total_count
      },
      data: payments
    }

    {:ok, response}
  end

  def create_payment(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "create_payment") do
      do_create_payment(authorize_args)
    else
      other -> other
    end
  end

  def do_create_payment(args) do
    with {:ok, payment} <- Service.create_payment(args[:fields], args[:opts]) do
      payment = Translation.translate(payment, args[:opts][:locale], args[:opts][:account].default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: args[:opts][:locale] }, data: payment }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_payment(request) do
    with {:ok, request} <- preprocess_request(request, "balance.get_payment") do
      request
      |> do_get_payment()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_payment(request = %{ account: account, params: %{ "id" => id } }) do
    payment =
      %{ id: id }
      |> Service.get_payment(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    if payment do
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: payment }}
    else
      {:error, :not_found}
    end
  end

  def update_payment(request) do
    with {:ok, request} <- preprocess_request(request, "balance.update_payment") do
      request
      |> do_update_payment()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_payment(request = %{ account: account, params: %{ "id" => id } }) do
    with {:ok, payment} <- Service.update_payment(id, request.fields, get_sopts(request)) do
      payment = Translation.translate(payment, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: payment }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_payment(request) do
    with {:ok, request} <- preprocess_request(request, "balance.delete_payment") do
      request
      |> do_delete_payment()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_payment(%{ account: account, params: %{ "id" => id } }) do
    with {:ok, _} <- Service.delete_payment(id, %{ account: account }) do
      {:ok, %AccessResponse{}}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  #
  # MARK: Refund
  #
  def create_refund(request) do
    with {:ok, request} <- preprocess_request(request, "balance.create_refund") do
      request
      |> do_create_refund()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_refund(request = %{ account: account, params: %{ "payment_id" => payment_id } }) do
    fields = Map.merge(request.fields, %{ "payment_id" => payment_id })

    with {:ok, refund} <- Service.create_refund(fields, get_sopts(request)) do
      refund = Translation.translate(refund, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: refund }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

end
