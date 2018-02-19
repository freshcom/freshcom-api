defmodule BlueJet.Balance do
  use BlueJet, :context
  use BlueJet.EventEmitter, namespace: :balance

  alias BlueJet.Balance.Service

  def update_settings(request) do
    with {:ok, request} <- preprocess_request(request, "balance.update_settings") do
      request
      |> do_update_settings()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_settings(request = %{ account: account }) do
    with {:ok, settings} <- Service.update_settings(request.fields, get_sopts(request)) do
      settings = Translation.translate(settings, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: settings }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def get_settings(request) do
    with {:ok, request} <- preprocess_request(request, "balance.get_settings") do
      request
      |> do_get_settings()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_get_settings(request = %{ account: account }) do
    settings =
      Service.get_settings(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    if settings do
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: settings }}
    else
      {:error, :not_found}
    end
  end

  #
  # MARK: Card
  #
  def list_card(request) do
    with {:ok, request} <- preprocess_request(request, "balance.list_card") do
      request
      |> do_list_card()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_card(request = %{ account: account, filter: filter }) do
    filter = Map.put(filter, :status, "saved_by_owner")

    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_card(%{ account: account })

    all_count =
      %{ filter: %{ status: "saved_by_owner" } }
      |> Service.count_card(%{ account: account })

    cards =
      %{ filter: filter, search: request.search }
      |> Service.list_card(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count,
      },
      data: cards
    }

    {:ok, response}
  end

  def update_card(request) do
    with {:ok, request} <- preprocess_request(request, "balance.update_card") do
      request
      |> do_update_card()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_card(request = %{ account: account, params: %{ "id" => id }}) do
    with {:ok, card} <- Service.update_card(id, request.fields, get_sopts(request)) do
      card = Translation.translate(card, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: card }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  def delete_card(request) do
    with {:ok, request} <- preprocess_request(request, "balance.delete_card") do
      request
      |> do_delete_card()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_delete_card(%{ account: account, params: %{ "id" => id } }) do
    with {:ok, _} <- Service.delete_card(id, %{ account: account }) do
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
    with {:ok, request} <- preprocess_request(request, "balance.list_payment") do
      request
      |> AccessRequest.transform_by_role()
      |> do_list_payment()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  # TODO: Customer can only view its own payment
  def do_list_payment(request = %AccessRequest{ account: account, filter: filter }) do
    total_count =
      %{ filter: filter, search: request.search }
      |> Service.count_payment(%{ account: account })

    all_count = Service.count_payment(%{ account: account })

    payments =
      %{ filter: filter, search: request.search }
      |> Service.list_payment(get_sopts(request))
      |> Translation.translate(request.locale, account.default_locale)

    response = %AccessResponse{
      meta: %{
        locale: request.locale,
        all_count: all_count,
        total_count: total_count
      },
      data: payments
    }

    {:ok, response}
  end

  def create_payment(request) do
    with {:ok, request} <- preprocess_request(request, "balance.create_payment") do
      request
      |> do_create_payment()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_payment(request = %{ account: account }) do
    with {:ok, payment} <- Service.create_payment(request.fields, get_sopts(request)) do
      payment = Translation.translate(payment, request.locale, account.default_locale)
      {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: payment }}
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

    # request = %{ request | locale: account.default_locale }

    # fields = Map.merge(request.fields, %{ "payment_id" => payment_id })
    # refund = %Refund{ account_id: account.id, account: account }
    # changeset = Refund.changeset(refund, fields, request.locale, account.default_locale)

    # statements =
    #   Multi.new()
    #   |> Multi.insert(:refund, changeset)
    #   |> Multi.run(:processed_refund, fn(%{ refund: refund }) ->
    #       Refund.process(refund, changeset)
    #      end)
    #   |> Multi.run(:payment, fn(%{ processed_refund: refund }) ->
    #       payment = Repo.get!(Payment, refund.payment_id)
    #       refunded_amount_cents = payment.refunded_amount_cents + refund.amount_cents
    #       refunded_processor_fee_cents = payment.refunded_processor_fee_cents + refund.processor_fee_cents
    #       refunded_freshcom_fee_cents = payment.refunded_freshcom_fee_cents + refund.freshcom_fee_cents
    #       gross_amount_cents = payment.amount_cents - refunded_amount_cents
    #       net_amount_cents = gross_amount_cents - payment.processor_fee_cents + refunded_processor_fee_cents - payment.freshcom_fee_cents + refunded_freshcom_fee_cents

    #       payment_status = cond do
    #         refunded_amount_cents >= payment.amount_cents -> "refunded"
    #         refunded_amount_cents > 0 -> "partially_refunded"
    #         true -> payment.status
    #       end

    #       payment
    #       |> Changeset.change(
    #           status: payment_status,
    #           refunded_amount_cents: refunded_amount_cents,
    #           refunded_processor_fee_cents: refunded_processor_fee_cents,
    #           refunded_freshcom_fee_cents: refunded_freshcom_fee_cents,
    #           gross_amount_cents: gross_amount_cents,
    #           net_amount_cents: net_amount_cents
    #          )
    #       |> Repo.update!()

    #       {:ok, payment}
    #      end)
    #   |> Multi.run(:after_create, fn(%{ processed_refund: refund }) ->
    #       emit_event("balance.refund.create.success", %{ refund: refund })
    #       {:ok, refund}
    #      end)

    # case Repo.transaction(statements) do
    #   {:ok, %{ processed_refund: refund }} ->
    #     refund_response(refund, request)

    #   {:error, _, errors, _} ->
    #     {:error, %AccessResponse{ errors: errors }}

    #   other -> other
    # end
  end

end
