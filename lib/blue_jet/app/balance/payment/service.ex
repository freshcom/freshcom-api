defmodule BlueJet.Balance.Payment.Service do
  @moduledoc false

  use BlueJet, :service

  import BlueJet.Balance.Card.Service, only: [create_card: 2]

  alias BlueJet.Balance.{Payment, Settings}
  alias BlueJet.Balance.Payment.{Query, Proxy}

  @spec list_payment(map, map) :: [Payment.t()]
  def list_payment(query \\ %{}, opts), do: default_list(Query, query, opts)

  @spec count_payment(map, map) :: integer
  def count_payment(query \\ %{}, opts), do: default_count(Query, query, opts)

  @doc """
  Creates a payment.

  Depending on the fields that are passed in a corresponding card may also be created.
  """
  @spec create_payment(map, map) :: {:ok, Payment.t()} | {:error, %{errors: keyword}}
  def create_payment(fields, opts) do
    account = extract_account(opts)
    preload = extract_preload(opts)

    changeset =
      %Payment{account_id: account.id, account: account}
      |> Payment.changeset(:insert, fields)

    statements =
      Multi.new()
      |> Multi.run(:before_create, fn(_) ->
        dispatch("balance:payment.create.before", %{changeset: changeset})
      end)
      |> Multi.run(:changeset, fn(_) -> put_stripe_customer_id(changeset) end)
      |> Multi.run(:initial_payment, &Repo.insert(&1[:changeset]))
      |> Multi.run(:payment, &charge_payment(&1[:initial_payment]))
      |> Multi.run(:_dispatch, fn %{payment: payment} ->
        dispatch("balance:payment.create.success", %{payment: payment, account: account})
      end)

    case Repo.transaction(statements) do
      {:ok, %{payment: payment}} ->
        payment = preload(payment, preload[:paths], preload[:opts])
        {:ok, payment}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  defp put_stripe_customer_id(%{valid?: true} = changeset) do
    identifiers = %{
      account: get_field(changeset, :account),
      owner_id: get_field(changeset, :owner_id),
      owner_type: get_field(changeset, :owner_type)
    }
    owner = Proxy.get_owner(identifiers)

    changeset = if owner do
      {:ok, owner} = ensure_stripe_customer_id(owner)
      put_change(changeset, :stripe_customer_id, owner.id)
    else
      changeset
    end

    {:ok, changeset}
  end

  defp put_stripe_customer_id(changeset), do: {:error, changeset}

  defp ensure_stripe_customer_id(%{stripe_customer_id: nil} = owner) do
    with {:ok, scustomer} <- Proxy.create_stripe_customer(owner),
         {:ok, owner} <- Proxy.update_owner(owner, %{stripe_customer_id: scustomer["id"]}) do
      {:ok, owner}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_stripe_customer_id(owner), do: owner

  @doc """
  Charge the payment through Stripe.

  If the payment has `:owner_id` and `:owner_type` set then this function will
  also create a card using the `:source` of the payment.

  Note that this function will create a card regardless of the `:save_source`
  fields. The `:save_source` will however effect the status of the resulting card,
  if `:save_source` is `true` then the status of the created card will be
  `"saved_by_owner"` otherwise it will be `"kept_by_system"`.
  """
  @spec charge_payment(Payment.t()) :: {:ok, Payment.t()} | {:error, %{errors: keyword}}
  def charge_payment(%{gateway: "freshcom", owner_id: nil, owner_type: nil} = payment) do
    settings = Settings.for_account(payment.account_id)
    stripe_user_id = settings.stripe_user_id
    Payment.put_destination_amount_cents(payment, settings)

    case Proxy.create_stripe_charge(payment, payment.source, stripe_user_id) do
      {:ok, stripe_charge} ->
        sync_from_stripe_charge(payment, stripe_charge)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def charge_payment(%{gateway: "freshcom"} = payment) do
    settings = Settings.for_account(payment.account_id)
    stripe_user_id = settings.stripe_user_id
    card_status = if payment.save_source, do: "saved_by_owner", else: "kept_by_system"
    card_fields = %{
      status: card_status,
      owner_id: payment.owner_id,
      owner_type: payment.owner_type,
      source: payment.source,
      stripe_customer_id: payment.stripe_customer_id
    }

    payment = Payment.put_destination_amount_cents(payment, settings)

    with {:ok, card} <- create_card(card_fields, %{account: payment.account}),
         {:ok, stripe_charge} <- Proxy.create_stripe_charge(payment, card.stripe_card_id, stripe_user_id) do
      sync_from_stripe_charge(payment, stripe_charge)
    else
      {:error, %{errors: _} = errors} ->
        {:error, errors}

      {:error, stripe_errors} ->
        {:error, format_stripe_errors(stripe_errors)}
    end
  end

  def charge_payment(payment), do: {:ok, payment}

  defp sync_from_stripe_charge(payment, %{"captured" => true} = stripe_charge) do
    transfer_amount = stripe_charge["transfer"]["amount"]
    amount = stripe_charge["amount"]

    processor_fee_cents = stripe_charge["balance_transaction"]["fee"]
    freshcom_fee_cents = amount - transfer_amount - processor_fee_cents

    gross_amount_cents = amount - payment.refunded_amount_cents
    net_amount_cents = transfer_amount

    payment =
      payment
      |> change(
        stripe_charge_id: stripe_charge["id"],
        stripe_transfer_id: stripe_charge["transfer"]["id"],
        status: "paid",
        amount_cents: amount,
        gross_amount_cents: gross_amount_cents,
        processor_fee_cents: processor_fee_cents,
        freshcom_fee_cents: freshcom_fee_cents,
        net_amount_cents: net_amount_cents
      )
      |> Repo.update!()

    {:ok, payment}
  end

  defp sync_from_stripe_charge(payment, %{"captured" => false} = stripe_charge) do
    stripe_charge_id = stripe_charge["id"]
    amount = stripe_charge["amount"]

    payment =
      payment
      |> change(
        stripe_charge_id: stripe_charge_id,
        status: "authorized",
        authorized_amount_cents: amount
      )
      |> Repo.update!()

    {:ok, payment}
  end

  defp format_stripe_errors(%{} = stripe_errors) do
    %{errors: [source: {stripe_errors["error"]["message"], code: stripe_errors["error"]["code"]}]}
  end

  defp format_stripe_errors(stripe_errors), do: stripe_errors

  @spec get_payment(map, map) :: Payment.t() | nil
  def get_payment(identifiers, opts), do: default_get(Query, identifiers, opts)

  @spec update_payment(nil, map, map) :: {:error, :not_found}
  def update_payment(nil, _, _), do: {:error, :not_found}

  @spec update_payment(Payment.t(), map, map) :: {:ok, Payment.t()} | {:error, %{errors: keyword}}
  def update_payment(%Payment{} = payment, fields, opts) do
    account = extract_account(opts)
    preload = extract_preload(opts)

    changeset =
      %{payment | account: account}
      |> Payment.changeset(:update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.update(:initial_payment, changeset)
      |> Multi.run(:payment, fn(%{initial_payment: payment}) ->
        if Payment.is_capturable?(payment) do
          capture_payment(payment)
        else
          {:ok, payment}
        end
      end)
      |> Multi.run(:_dispatch, fn %{payment: payment} ->
        dispatch("balance:payment.update.success", %{payment: payment, account: account})
      end)

    case Repo.transaction(statements) do
      {:ok, %{payment: payment}} ->
        {:ok, preload(payment, preload[:path], preload[:opts])}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  @spec update_payment(map, map, map) :: {:ok, Payment.t()} | {:error, %{errors: keyword}} | {:error, :not_found}
  def update_payment(identifiers, fields, opts) do
    get_payment(identifiers, Map.put(opts, :preload, %{}))
    |> update_payment(fields, opts)
  end

  @doc """
  Capture a payment.

  If the given payment is not a capturable payment this function will immediately return `{:ok, payment}`.
  """
  @spec capture_payment(Payment.t()) :: {:ok, Payment.t()} | {:error, %{errors: keyword}}
  def capture_payment(%{gateway: "freshcom", status: "authorized"} = payment) do
    with {:ok, _} <- Proxy.capture_stripe_charge(payment) do
      payment =
        payment
        |> change(status: "paid")
        |> Repo.update!()

      #TODO: need to sync from stripe charge
      {:ok, payment}
    else
      {:error, stripe_errors} ->
        {:error, format_stripe_errors(stripe_errors)}

      other ->
        other
    end
  end

  def delete_payment(nil, _), do: {:error, :not_found}

  def delete_payment(%Payment{} = payment, opts) do
    delete(payment, opts)
  end

  def delete_payment(identifiers, opts) do
    get_payment(identifiers, Map.merge(opts, %{preloads: %{}}))
    |> delete_payment(opts)
  end

  def delete_all_payment(opts) do
    delete_all(Payment, opts)
  end
end