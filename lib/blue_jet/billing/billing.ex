defmodule BlueJet.Billing do
  use BlueJet, :context

  alias Ecto.Changeset
  alias Ecto.Multi

  alias BlueJet.Identity

  alias BlueJet.Billing.Payment
  alias BlueJet.Billing.Refund
  alias BlueJet.Billing.Card
  alias BlueJet.Billing.StripeAccount

  alias BlueJet.FileStorage.ExternalFile

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

  def create_stripe_account(request = %AccessRequest{ vas: vas }) do
    with {:ok, role} <- Identity.authorize(vas, "billing.create_stripe_account") do
      do_create_stripe_account(request)
    else
      {:error, reason} -> {:error, :access_denied}
    end
  end
  def do_create_stripe_account(request = %AccessRequest{ vas: vas }) do
    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })
    changeset = StripeAccount.changeset(%StripeAccount{}, fields)

    statements = Multi.new()
    |> Multi.insert(:stripe_account, changeset)
    |> Multi.run(:processed_stripe_account, fn(%{ stripe_account: stripe_account }) ->
        StripeAccount.process(stripe_account, changeset)
       end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_stripe_account: stripe_account }} ->
        {:ok, %AccessResponse{ data: stripe_account }}
      {:error, _, errors, _} ->
        {:error, %AccessResponse{ errors: errors }}
    end
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

    statements = Multi.new()
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
      {:error, _, errors, _} ->
        {:error, %AccessResponse{ errors: errors }}
    end
  end

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

  def update_payment(request = %{ vas: vas, payment_id: payment_id }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)
    payment = Repo.get_by!(Payment, account_id: vas[:account_id], id: payment_id)
    update_payment(Payment.changeset(payment, request.fields), request.fields)
  end
  def update_payment(changeset = %Changeset{ valid?: true }, options) do
    Repo.transaction(fn ->
      payment = Repo.update!(changeset)
      with {:ok, payment} <- Payment.process(payment, changeset) do
        payment
      else
        {:error, errors} -> Repo.rollback(errors)
      end
    end)
  end
  def update_payment(changeset, _) do
    {:error, changeset.errors}
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
  def create_refund(request = %{ vas: vas }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)
    fields = Map.merge(request.fields, %{ "account_id" => vas[:account_id] })

    with changeset = %Changeset{ valid?: true } <- Refund.changeset(%Refund{}, fields),
      {:ok, refund} <- Repo.transaction(fn ->

        refund = Repo.insert!(changeset) |> Repo.preload(:payment)
        new_refunded_amount_cents = refund.payment.refunded_amount_cents + refund.amount_cents
        new_payment_status = if new_refunded_amount_cents >= refund.payment.paid_amount_cents do
          "refunded"
        else
          "partially_refunded"
        end

        payment_changeset = Changeset.change(refund.payment, %{ refunded_amount_cents: new_refunded_amount_cents, status: new_payment_status })
        payment = Repo.update!(payment_changeset)

        with {:ok, refund} <- process_refund(refund, payment) do
          refund
        else
          {:error, errors} -> Repo.rollback(errors)
        end

      end)
    do
      {:ok, refund}
    else
      {:error, changeset = %Changeset{}} -> {:error, changeset.errors}
      changeset = %Changeset{} -> {:error, changeset.errors}
      other -> other
    end
  end

  defp process_refund(refund, payment = %Payment{ gateway: "online", processor: "stripe" }) do
    with {:ok, stripe_refund} <- create_stripe_refund(refund, payment) do
      {:ok, refund}
    else
      {:error, stripe_errors} -> {:error, format_stripe_errors(stripe_errors)}
    end
  end
  defp process_refund(refund, _), do: {:ok, refund}

  defp create_stripe_refund(refund, payment) do
    StripeClient.post("/refunds", %{ charge: payment.stripe_charge_id, amount: refund.amount_cents, metadata: %{ fc_refund_id: refund.id }  })
  end
end
