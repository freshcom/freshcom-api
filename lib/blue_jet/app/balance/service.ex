defmodule BlueJet.Balance.Service do
  use BlueJet, :service

  alias BlueJet.Balance.{Settings, Card, Payment, Refund}

  #
  # MARK: Settings
  #
  def create_settings(opts) do
    account = extract_account(opts)

    %Settings{account: account, account_id: account.id}
    |> Repo.insert()
  end

  def get_settings(opts) do
    account = extract_account(opts)
    Repo.get_by(Settings, account_id: account.id)
  end

  def update_settings(nil, _, _), do: {:error, :not_found}

  def update_settings(settings, fields, opts) do
    account = extract_account(opts)

    changeset =
      %{settings | account: account}
      |> Settings.changeset(:update, fields)

    statements =
      Multi.new()
      |> Multi.update(:settings, changeset)
      |> Multi.run(:account, &Settings.Proxy.sync_to_account(&1[:settings]))

    case Repo.transaction(statements) do
      {:ok, %{settings: settings}} ->
        {:ok, settings}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_settings(fields, opts) do
    get_settings(opts)
    |> update_settings(fields, opts)
  end

  def delete_settings(opts) do
    get_settings(opts)
    |> delete_settings(opts)
  end

  def delete_settings(%Settings{} = settings, _) do
    with {:ok, settings} <- Repo.delete(settings) do
      {:ok, settings}
    else
      other -> other
    end
  end

  #
  # MARK: Card
  #
  defdelegate list_card(query \\ %{}, opts), to: Card.Service
  defdelegate count_card(query \\ %{}, opts), to: Card.Service
  defdelegate create_card(fields, opts), to: Card.Service
  defdelegate get_card(identifiers, opts), to: Card.Service
  defdelegate update_card(identifiers_or_card, fields, opts), to: Card.Service
  defdelegate delete_card(identifiers_or_card, opts), to: Card.Service
  defdelegate delete_all_card(opts), to: Card.Service

  #
  # MARK: Payment
  #
  defdelegate list_payment(query \\ %{}, opts), to: Payment.Service
  defdelegate count_payment(query \\ %{}, opts), to: Payment.Service
  defdelegate create_payment(fields, opts), to: Payment.Service
  defdelegate get_payment(identifiers, opts), to: Payment.Service
  defdelegate update_payment(identifiers_or_payment, fields, opts), to: Payment.Service
  defdelegate delete_payment(identifiers_or_payment, opts), to: Payment.Service
  defdelegate delete_all_payment(opts), to: Payment.Service

  #
  # MARK: Refund
  #
  def create_refund(fields, opts) do
    account = extract_account(opts)
    preload = extract_preload(opts)

    changeset =
      %Refund{account_id: account.id, account: account}
      |> Refund.changeset(:insert, fields)

    statements =
      Multi.new()
      |> Multi.insert(:initial_refund, changeset)
      |> Multi.run(:process_refund, &process_refund(&1[:initial_refund]))
      |> Multi.run(:refund, &sync_to_payment(&1[:process_refund]))
      |> Multi.run(:_dispatch, &dispatch("balance:refund.create.success", %{refund: &1[:refund]}, force_ok: true))

    case Repo.transaction(statements) do
      {:ok, %{refund: refund}} ->
        {:ok, preload(refund, preload[:paths], preload[:opts])}

      {:error, _, changeset, _} ->
        {:error, changeset}

      other ->
        other
    end
  end

  defp process_refund(%{gateway: "freshcom"} = refund) do
    with {:ok, stripe_refund} <- Refund.Proxy.create_stripe_refund(refund),
         {:ok, stripe_transfer_reversal} <- Refund.Proxy.create_stripe_transfer_reversal(refund, stripe_refund) do
      sync_from_stripe_refund_and_transfer_reversal(refund, stripe_refund, stripe_transfer_reversal)
    else
      {:error, stripe_errors} ->
        {:error, format_stripe_errors(stripe_errors)}

      other ->
        other
    end
  end

  defp process_refund(refund), do: {:ok, refund}

  defp sync_from_stripe_refund_and_transfer_reversal(refund, stripe_refund, stripe_transfer_reversal) do
    processor_fee_cents = -stripe_refund["balance_transaction"]["fee"]
    freshcom_fee_cents = refund.amount_cents - stripe_transfer_reversal["amount"] - processor_fee_cents

    refund =
      refund
      |> change(
        stripe_refund_id: stripe_refund["id"],
        stripe_transfer_reversal_id: stripe_transfer_reversal["id"],
        processor_fee_cents: processor_fee_cents,
        freshcom_fee_cents: freshcom_fee_cents,
        status: stripe_refund["status"]
      )
      |> Repo.update!()

    {:ok, refund}
  end

  defp sync_to_payment(refund) do
    payment = Repo.get(Payment, refund.payment_id)

    refunded_amount_cents = payment.refunded_amount_cents + refund.amount_cents
    refunded_processor_fee_cents =  payment.refunded_processor_fee_cents + refund.processor_fee_cents
    refunded_freshcom_fee_cents = payment.refunded_freshcom_fee_cents + refund.freshcom_fee_cents

    gross_amount_cents = payment.amount_cents - refunded_amount_cents

    net_amount_cents =
      gross_amount_cents - payment.processor_fee_cents + refunded_processor_fee_cents -
      payment.freshcom_fee_cents + refunded_freshcom_fee_cents

    payment_status =
      cond do
        refunded_amount_cents >= payment.amount_cents -> "refunded"
        refunded_amount_cents > 0 -> "partially_refunded"
        true -> payment.status
      end

    payment =
      payment
      |> change(
        status: payment_status,
        refunded_amount_cents: refunded_amount_cents,
        refunded_processor_fee_cents: refunded_processor_fee_cents,
        refunded_freshcom_fee_cents: refunded_freshcom_fee_cents,
        gross_amount_cents: gross_amount_cents,
        net_amount_cents: net_amount_cents
      )
      |> Repo.update!()

    {:ok, %{refund | payment: payment}}
  end

  defp format_stripe_errors(%{} = stripe_errors) do
    %{errors: [source: {stripe_errors["error"]["message"], code: stripe_errors["error"]["code"]}]}
  end

  defp format_stripe_errors(stripe_errors), do: stripe_errors
end
