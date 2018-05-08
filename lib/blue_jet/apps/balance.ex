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
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: settings }}
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
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: settings }}
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
      |> Translation.translate(args[:locale], args[:default_locale])

    response = %AccessResponse{
      meta: %{
        locale: args[:locale],
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
      card = Translation.translate(card, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: card }}
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
      |> Translation.translate(args[:locale], account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: args[:locale],
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
      payment = Translation.translate(payment, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: payment }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_payment(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "get_payment") do
      do_get_payment(authorize_args)
    else
      other -> other
    end
  end

  def do_get_payment(args) do
    payment =
      Service.get_payment(args[:identifiers], args[:opts])
      |> Translation.translate(args[:locale], args[:default_locale])

    if payment do
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: payment }}
    else
      {:error, :not_found}
    end
  end

  def update_payment(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "update_payment") do
      do_update_payment(authorize_args)
    else
      other -> other
    end
  end

  def do_update_payment(args) do
    with {:ok, payment} <- Service.update_payment(args[:id], args[:fields], args[:opts]) do
      payment = Translation.translate(payment, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: payment }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_payment(request) do
    with {:ok, authorize_args} <- Policy.authorize(request, "delete_payment") do
      do_delete_payment(authorize_args)
    else
      other -> other
    end
  end

  def do_delete_payment(args) do
    with {:ok, _} <- Service.delete_payment(args[:id], args[:opts]) do
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
    with {:ok, authorize_args} <- Policy.authorize(request, "create_refund") do
      do_create_refund(authorize_args)
    else
      other -> other
    end
  end

  def do_create_refund(args) do
    with {:ok, refund} <- Service.create_refund(args[:fields], args[:opts]) do
      refund = Translation.translate(refund, args[:locale], args[:default_locale])
      {:ok, %AccessResponse{ meta: %{ locale: args[:locale] }, data: refund }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

end
