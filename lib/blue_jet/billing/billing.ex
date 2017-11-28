defmodule BlueJet.Billing do
  use BlueJet, :context

  alias Ecto.Changeset
  alias Ecto.Multi

  alias BlueJet.Identity

  alias BlueJet.Billing.Payment
  alias BlueJet.Billing.Refund
  alias BlueJet.Billing.Card
  alias BlueJet.Billing.BillingSettings

  def run_event_handler(name, data) do
    listeners = Map.get(Application.get_env(:blue_jet, :billing, %{}), :listeners, [])

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
    changeset = BillingSettings.changeset(%BillingSettings{}, %{ account_id: account.id })
    billing_settings = Repo.insert!(changeset)

    {:ok, billing_settings}
  end
  def handle_event(_, data), do: {:ok, nil}

  def update_billing_settings(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "billing.update_settings") do
      do_update_billing_settings(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_update_billing_settings(request = %AccessRequest{ vas: vas }) do
    billing_settings = Repo.get_by!(BillingSettings, account_id: vas[:account_id])
    changeset = BillingSettings.changeset(billing_settings, request.fields)

    statements = Multi.new()
    |> Multi.update(:billing_settings, changeset)
    |> Multi.run(:processed_billing_settings, fn(%{ billing_settings: billing_settings }) ->
        BillingSettings.process(billing_settings, changeset)
       end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_billing_settings: billing_settings }} ->
        {:ok, %AccessResponse{ data: billing_settings }}
      {:error, _, errors, _} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def get_billing_settings(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "billing.get_settings") do
      do_get_billing_settings(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_get_billing_settings(request = %AccessRequest{ vas: vas }) do
    billing_settings = Repo.get_by!(BillingSettings, account_id: vas[:account_id])

    {:ok, %AccessResponse{ data: billing_settings }}
  end

  def list_card(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "billing.list_card") do
      do_list_card(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_list_card(request = %AccessRequest{ vas: %{ account_id: account_id }, filter: filter, pagination: pagination }) do
    query =
      Card.Query.default()
      |> filter_by(status: "saved_by_owner")
      |> filter_by(owner_id: filter[:owner_id], owner_type: filter[:owner_type])
      |> Card.Query.for_account(account_id)

    result_count = Repo.aggregate(query, :count, :id)

    total_query = Card |> Card.Query.for_account(account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: pagination[:size], number: pagination[:number])

    cards =
      Repo.all(query)
      |> Translation.translate(request.locale)

    response = %AccessResponse{
      meta: %{
        total_count: total_count,
        result_count: result_count,
      },
      data: cards
    }

    {:ok, response}
  end

  def update_card(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "billing.update_card") do
      do_update_card(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_update_card(request = %AccessRequest{ vas: vas, params: %{ card_id: card_id }}) do
    card = Card |> Card.Query.for_account(vas[:account_id]) |> Repo.get(card_id)

    with %Card{} <- card,
         changeset = %{valid?: true} <- Card.changeset(card, request.fields)

    do
      statements =
        Multi.new()
        |> Multi.update(:card, changeset)
        |> Multi.run(:processed_card, fn(%{ card: card }) ->
            Card.process(card, changeset)
           end)

      {:ok, %{ processed_card: card }} = Repo.transaction(statements)
      {:ok, %AccessResponse{ data: card }}
    else
      {:error, %{ errors: errors }} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  def delete_card(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "billing.delete_card") do
      do_delete_card(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_delete_card(%AccessRequest{ vas: vas, params: %{ card_id: card_id } }) do
    card = Card |> Card.Query.for_account(vas[:account_id]) |> Repo.get!(card_id)

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
  def list_payment(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "billing.list_payment") do
      do_list_payment(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_list_payment(request = %AccessRequest{ vas: %{ account_id: account_id }, filter: filter, pagination: pagination }) do
    query =
      Payment.Query.default()
      |> filter_by(
          target_id: filter[:target_id],
          target_type: filter[:target_type],
          owner_id: filter[:owner_id],
          owner_type: filter[:owner_type]
         )
      |> Payment.Query.for_account(account_id)
    result_count = Repo.aggregate(query, :count, :id)

    total_query = Payment |> Payment.Query.for_account(account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: pagination[:size], number: pagination[:number])

    payments =
      Repo.all(query)
      |> Repo.preload(Payment.Query.preloads(request.preloads))
      |> Translation.translate(request.locale)

    response = %AccessResponse{
      meta: %{
        total_count: total_count,
        result_count: result_count,
      },
      data: payments
    }

    {:ok, response}
  end
  def list_payment_for_target(target_type, target_id) do
    Payment |> Payment.Query.for_target(target_type, target_id) |> Repo.all()
  end

  def create_payment(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "billing.create_payment") do
      do_create_payment(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_create_payment(request = %AccessRequest{ vas: vas }) do
    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })

    owner = %{ id: fields["owner_id"], type: fields["owner_type"] }
    target = %{ id: fields["target_id"], type: fields["target_type"]}

    statements =
      Multi.new()
      |> Multi.run(:fields, fn(_) ->
          run_payment_before_create(fields, owner, target)
         end)
      |> Multi.run(:changeset, fn(%{ fields: fields }) ->
          {:ok, Payment.changeset(%Payment{}, fields)}
         end)
      |> Multi.run(:payment, fn(%{ changeset: changeset }) ->
          Repo.insert(changeset)
         end)
      |> Multi.run(:processed_payment, fn(%{ payment: payment, changeset: changeset }) ->
          Payment.process(payment, changeset)
         end)
      |> Multi.run(:after_create, fn(%{ processed_payment: payment }) ->
          run_event_handler("billing.payment.created", %{ payment: payment })
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_payment: payment }} ->
        {:ok, %AccessResponse{ data: payment }}
      {:error, :payment, %{ errors: errors}, _ } ->
        {:error, %AccessResponse{ errors: errors }}
      {:error, _, errors, _} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  # Allow other services to change the fields of payment
  defp run_payment_before_create(fields, owner, target) do
    with {:ok, results} <- run_event_handler("billing.payment.before_create", %{ fields: fields, target: target, owner: owner }) do
      values = Keyword.values(results)
      fields = Enum.reduce(values, %{}, fn(fields, acc) ->
        Map.merge(acc, fields)
      end)

      {:ok, fields}
    else
      other -> other
    end
  end

  def get_payment(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "billing.get_payment") do
      do_get_payment(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_get_payment(request = %AccessRequest{ vas: vas, params: %{ payment_id: payment_id } }) do
    payment = Payment |> Payment.Query.for_account(vas[:account_id]) |> Repo.get(payment_id)

    if payment do
      payment =
        payment
        |> Repo.preload(Payment.Query.preloads(request.preloads))
        |> Translation.translate(request.locale)

      {:ok, %AccessResponse{ data: payment }}
    else
      {:error, :not_found}
    end
  end

  def update_payment(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "billing.update_payment") do
      do_update_payment(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_update_payment(request = %AccessRequest{ vas: vas, params: %{ payment_id: payment_id } }) do
    payment = Payment |> Payment.Query.for_account(vas[:account_id]) |> Repo.get(payment_id)

    with %Payment{} <- payment,
         changeset = %{valid?: true} <- Payment.changeset(payment, request.fields)
    do
      statements =
        Multi.new()
        |> Multi.update(:payment, changeset)
        |> Multi.run(:processed_payment, fn(%{ payment: payment }) ->
            Payment.process(payment, changeset)
           end)
        |> Multi.run(:after_update, fn(%{ processed_payment: payment}) ->
            run_event_handler("billing.payment.updated", %{ payment: payment })
           end)

      {:ok, %{ processed_payment: payment }} = Repo.transaction(statements)
      {:ok, %AccessResponse{ data: payment }}
    else
      nil -> {:error, :not_found}
      %{ errors: errors } ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

  defp format_stripe_errors(stripe_errors) do
    [source: { stripe_errors["error"]["message"], [code: stripe_errors["error"]["code"], full_error_message: true] }]
  end

  def delete_payment!(request = %{ vas: vas, payment_id: payment_id }) do
    payment = Repo.get_by!(Payment, account_id: vas[:account_id], id: payment_id)
    Repo.delete!(payment)
  end

  ######
  # Refund
  ######
  def create_refund(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "billing.create_refund") do
      do_create_refund(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_create_refund(request = %{ vas: vas }) do
    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })
    changeset = Refund.changeset(%Refund{}, fields)

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
          run_event_handler("billing.refund.created", %{ refund: refund })
          {:ok, refund}
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_refund: refund }} ->
        {:ok, %AccessResponse{ data: refund }}
      {:error, _, errors, _} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

end
