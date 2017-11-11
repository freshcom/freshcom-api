defmodule BlueJet.Billing do
  use BlueJet, :context

  alias Ecto.Changeset
  alias Ecto.Multi

  alias BlueJet.Identity

  alias BlueJet.Billing.Payment
  alias BlueJet.Billing.Refund
  alias BlueJet.Billing.Card

  alias BlueJet.FileStorage.ExternalFile

  def list_cards(request = %{ vas: vas, customer_id: target_customer_id }) do
    defaults = %{ preloads: [], fields: %{} }
    request = Map.merge(defaults, request)
    customer_id = vas[:customer_id] || target_customer_id
    account_id = vas[:account_id]

    query =
      Card
      |> filter_by(status: "saved_by_customer")
      |> where([c], c.account_id == ^account_id)
      |> where([c], c.customer_id == ^customer_id)

    result_count = Repo.aggregate(query, :count, :id)

    total_query = Card |> where([s], s.account_id == ^account_id)
    total_count = Repo.aggregate(total_query, :count, :id)

    query = paginate(query, size: request.page_size, number: request.page_number)

    cards =
      Repo.all(query)
      |> Translation.translate(request.locale)

    %{
      total_count: total_count,
      result_count: result_count,
      cards: cards
    }
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

  def get_payment!(request = %{ vas: vas, payment_id: payment_id }) do
    defaults = %{ locale: "en", preloads: [] }
    request = Map.merge(defaults, request)

    payment =
      Payment
      |> Repo.get_by!(account_id: vas[:account_id], id: payment_id)
      |> Payment.preload(request.preloads)
      |> Translation.translate(request.locale)

    payment
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
    changeset = Payment.changeset(%Payment{}, fields)

    owner = %{ id: fields["owner_id"], type: fields["owner_type"] }
    target = %{ id: fields["target_id"], type: fields["target_type"]}

    statements = Multi.new()
    |> Multi.run(:before_create, fn(_) ->
        run_event_handler("billing.payment.before_create", %{ target: target, owner: owner })
       end)
    |> Multi.insert(:payment, changeset)
    |> Multi.run(:processed_payment, fn(%{ payment: payment }) ->
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

  defp create_payment_by_changeset(changeset = %Changeset{ valid?: true }) do
    # We create the charge first so that stripe_charge can have a reference to the charge,
    # since stripe_charge can't be rolled back this avoid an orphan stripe_charge
    # so we need to make sure what the stripe_charge is for and refund manually if needed
    Repo.transaction(fn ->
      payment = Repo.insert!(changeset)

      with {:ok, payment} <- Payment.process(payment, changeset) do
        payment
      else
        {:error, errors} -> Repo.rollback(errors)
      end
    end)
  end
  def create_payment(changeset, _) do
    {:error, changeset.errors}
  end
  defp run_event_handler(name, data) do
    listeners = Map.get(Application.get_env(:blue_jet, :billing, %{}), :listeners, [])

    Enum.reduce_while(listeners, {:ok, []}, fn(listener, acc) ->
      IO.inspect listener
      with {:ok, result} <- listener.handle_event(name, data) do
        {:ok, result} = acc
        {:cont, {:ok, result ++ [{listener, result}]}}
      else
        {:error, errors} -> {:halt, {:error, errors}}
        other -> {:halt, other}
      end
    end)
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
