defmodule BlueJet.Balance do
  use BlueJet, :context

  alias Ecto.Changeset
  alias Ecto.Multi

  alias BlueJet.Balance.Payment
  alias BlueJet.Balance.Refund
  alias BlueJet.Balance.Card
  alias BlueJet.Balance.BalanceSettings

  def run_event_handler(name, data) do
    listeners = Map.get(Application.get_env(:blue_jet, :balance, %{}), :listeners, [])

    Enum.reduce_while(listeners, {:ok, []}, fn(listener, acc) ->
      with {:ok, result} <- listener.handle_event(name, data) do
        {:ok, acc_result} = acc
        {:cont, {:ok, acc_result ++ [{listener, result}]}}
      else
        {:error, errors} -> {:halt, {:error, errors}}
        other -> {:halt, other}
      end
    end)
  end

  def handle_event("identity.account.created", %{ account: account }) do
    changeset = BalanceSettings.changeset(%BalanceSettings{}, %{ account_id: account.id })
    balance_settings = Repo.insert!(changeset)

    {:ok, balance_settings}
  end
  def handle_event(_, _), do: {:ok, nil}

  def update_settings(request) do
    with {:ok, request} <- preprocess_request(request, "balance.update_settings") do
      request
      |> do_update_settings()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_update_settings(request = %{ account: account }) do
    balance_settings = Repo.get_by!(BalanceSettings, account_id: account.id)
    changeset = BalanceSettings.changeset(balance_settings, request.fields)

    statements = Multi.new()
    |> Multi.update(:balance_settings, changeset)
    |> Multi.run(:processed_balance_settings, fn(%{ balance_settings: balance_settings }) ->
        BalanceSettings.process(balance_settings, changeset)
       end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_balance_settings: balance_settings }} ->
        {:ok, %AccessResponse{ data: balance_settings }}

      {:error, _, errors, _} ->
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

  def do_get_settings(%{ account: account }) do
    balance_settings = Repo.get_by!(BalanceSettings, account_id: account.id)

    {:ok, %AccessResponse{ data: balance_settings }}
  end

  def list_card(request) do
    with {:ok, request} <- preprocess_request(request, "balance.list_card") do
      request
      |> AccessRequest.transform_by_role()
      |> do_list_card()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_card(request = %{ account: account, filter: filter, pagination: pagination }) do
    data_query =
      Card.Query.default()
      |> filter_by(status: "saved_by_owner", owner_id: filter[:owner_id], owner_type: filter[:owner_type])
      |> Card.Query.for_account(account.id)

    total_count = Repo.aggregate(data_query, :count, :id)
    all_count =
      Card
      |> filter_by(status: "saved_by_owner")
      |> Card.Query.for_account(account.id)
      |> Repo.aggregate(:count, :id)

    cards =
      data_query
      |> paginate(size: pagination[:size], number: pagination[:number])
      |> Repo.all()
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

  defp card_response(nil, _), do: {:error, :not_found}

  defp card_response(card, request = %{ account: account }) do
    preloads = Card.Query.preloads(request.preloads, role: request.role)

    card =
      card
      |> Repo.preload(preloads)
      |> Card.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: card }}
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
    card =
      Card.Query.default()
      |> Card.Query.for_account(account.id)
      |> Repo.get(id)

    with %Card{} <- card,
         changeset = %{valid?: true} <- Card.changeset(card, request.fields, request.locale, account.default_locale)
    do
      statements =
        Multi.new()
        |> Multi.update(:card, changeset)
        |> Multi.run(:processed_card, fn(%{ card: card }) ->
            Card.process(card, changeset)
           end)

      {:ok, %{ processed_card: card }} = Repo.transaction(statements)
      card_response(card, request)
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
    card =
      Card.Query.default()
      |> Card.Query.for_account(account.id)
      |> Repo.get(id)

    if card do
      Repo.transaction(fn ->
        Card.process(card, :delete)
        Repo.delete!(card)
      end)

      {:ok, %AccessResponse{}}
    else
      {:error, :not_found}
    end
  end

  ####
  # Payment
  ####
  def list_payment(request) do
    with {:ok, request} <- preprocess_request(request, "balance.list_payment") do
      request
      |> AccessRequest.transform_by_role()
      |> do_list_payment()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_list_payment(request = %AccessRequest{ account: account, filter: filter, pagination: pagination }) do
    data_query =
      Payment.Query.default()
      |> filter_by(
          target_id: filter[:target_id],
          target_type: filter[:target_type],
          owner_id: filter[:owner_id],
          owner_type: filter[:owner_type]
         )
      |> Payment.Query.for_account(account.id)

    total_count = Repo.aggregate(data_query, :count, :id)
    all_count =
      Payment.Query.default()
      |> Payment.Query.for_account(account.id)
      |> Repo.aggregate(:count, :id)

    preloads = Payment.Query.preloads(request.preloads, role: request.role)
    payments =
      data_query
      |> paginate(size: pagination[:size], number: pagination[:number])
      |> Repo.all()
      |> Repo.preload(preloads)
      |> Payment.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
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

  def list_payment_for_target(target_type, target_id) do
    Payment.Query.default()
    |> Payment.Query.for_target(target_type, target_id)
    |> Repo.all()
  end

  defp payment_response(nil, _), do: {:error, :not_found}

  defp payment_response(payment, request = %{ account: account }) do
    preloads = Payment.Query.preloads(request.preloads, role: request.role)

    payment =
      payment
      |> Repo.preload(preloads)
      |> Payment.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: payment }}
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
    request = %{ request | locale: account.default_locale }

    fields = Map.merge(request.fields, %{ "account_id" => account.id })

    owner = %{ id: fields["owner_id"], type: fields["owner_type"] }
    target = %{ id: fields["target_id"], type: fields["target_type"]}

    statements =
      Multi.new()
      |> Multi.run(:fields, fn(_) ->
          run_payment_before_create(fields, owner, target)
         end)
      |> Multi.run(:changeset, fn(%{ fields: fields }) ->
          {:ok, Payment.changeset(%Payment{}, fields, request.locale, account.default_locale)}
         end)
      |> Multi.run(:payment, fn(%{ changeset: changeset }) ->
          Repo.insert(changeset)
         end)
      |> Multi.run(:processed_payment, fn(%{ payment: payment, changeset: changeset }) ->
          Payment.process(payment, changeset)
         end)
      |> Multi.run(:after_create, fn(%{ processed_payment: payment }) ->
          run_event_handler("balance.payment.created", %{ payment: payment })
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_payment: payment }} ->
        {:ok, %AccessResponse{ data: payment }}

      {:error, :payment, %{ errors: errors}, _ } ->
        {:error, %AccessResponse{ errors: errors }}

      {:error, _, errors, _} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

  # Allow other services to change the fields of payment
  defp run_payment_before_create(fields, owner, target) do
    with {:ok, results} <- run_event_handler("balance.payment.before_create", %{ fields: fields, target: target, owner: owner }) do
      values = Keyword.values(results)
      fields = Enum.reduce(values, %{}, fn(fields, acc) ->
        if fields do
          Map.merge(acc, fields)
        else
          acc
        end
      end)

      {:ok, fields}
    else
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
      Payment.Query.default()
      |> Payment.Query.for_account(account.id)
      |> Repo.get(id)

    payment_response(payment, request)
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
    payment =
      Payment.Query.default()
      |> Payment.Query.for_account(account.id)
      |> Repo.get(id)

    with %Payment{} <- payment,
         changeset = %{valid?: true} <- Payment.changeset(payment, request.fields, request.locale, account.default_locale)
    do
      statements =
        Multi.new()
        |> Multi.update(:payment, changeset)
        |> Multi.run(:processed_payment, fn(%{ payment: payment }) ->
            Payment.process(payment, changeset)
           end)
        |> Multi.run(:after_update, fn(%{ processed_payment: payment}) ->
            run_event_handler("balance.payment.updated", %{ payment: payment })
           end)

      {:ok, %{ processed_payment: payment }} = Repo.transaction(statements)
      payment_response(payment, request)
    else
      nil -> {:error, :not_found}

      %{ errors: errors } ->
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
    payment =
      Payment.Query.default()
      |> Payment.Query.for_account(account.id)
      |> Repo.get(id)

    if payment do
      Repo.delete!(payment)
      {:ok, %AccessResponse{}}
    else
      {:error, :not_found}
    end
  end

  ######
  # Refund
  ######
  defp refund_response(nil, _), do: {:error, :not_found}

  defp refund_response(refund, request = %{ account: account }) do
    preloads = Refund.Query.preloads(request.preloads, role: request.role)

    refund =
      refund
      |> Repo.preload(preloads)
      |> Refund.put_external_resources(request.preloads, %{ account: account, role: request.role, locale: request.locale })
      |> Translation.translate(request.locale, account.default_locale)

    {:ok, %AccessResponse{ meta: %{ locale: request.locale }, data: refund }}
  end

  def create_refund(request) do
    with {:ok, request} <- preprocess_request(request, "balance.create_refund") do
      request
      |> do_create_refund()
    else
      {:error, _} -> {:error, :access_denied}
    end
  end

  def do_create_refund(request = %{ account: account, params: %{ "payment_id" => payment_id } }) do
    request = %{ request | locale: account.default_locale }

    fields = Map.merge(request.fields, %{
      "account_id" => account.id,
      "payment_id" => payment_id
    })
    changeset = Refund.changeset(%Refund{}, fields, request.locale, account.default_locale)

    statements =
      Multi.new()
      |> Multi.insert(:refund, changeset)
      |> Multi.run(:processed_refund, fn(%{ refund: refund }) ->
          Refund.process(refund, changeset)
         end)
      |> Multi.run(:payment, fn(%{ processed_refund: refund }) ->
          payment = Repo.get!(Payment, refund.payment_id)
          refunded_amount_cents = payment.refunded_amount_cents + refund.amount_cents
          refunded_processor_fee_cents = payment.refunded_processor_fee_cents + refund.processor_fee_cents
          refunded_freshcom_fee_cents = payment.refunded_freshcom_fee_cents + refund.freshcom_fee_cents
          gross_amount_cents = payment.amount_cents - refunded_amount_cents
          net_amount_cents = gross_amount_cents - payment.processor_fee_cents + refunded_processor_fee_cents - payment.freshcom_fee_cents + refunded_freshcom_fee_cents

          payment_status = cond do
            refunded_amount_cents >= payment.amount_cents -> "refunded"
            refunded_amount_cents > 0 -> "partially_refunded"
            true -> payment.status
          end

          payment
          |> Changeset.change(
              status: payment_status,
              refunded_amount_cents: refunded_amount_cents,
              refunded_processor_fee_cents: refunded_processor_fee_cents,
              refunded_freshcom_fee_cents: refunded_freshcom_fee_cents,
              gross_amount_cents: gross_amount_cents,
              net_amount_cents: net_amount_cents
             )
          |> Repo.update!()

          {:ok, payment}
         end)
      |> Multi.run(:after_create, fn(%{ processed_refund: refund }) ->
          run_event_handler("balance.refund.created", %{ refund: refund })
          {:ok, refund}
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_refund: refund }} ->
        refund_response(refund, request)

      {:error, _, errors, _} ->
        {:error, %AccessResponse{ errors: errors }}

      other -> other
    end
  end

end
