defmodule BlueJet.Balance.Payment.Service do
  use BlueJet, :service

  import BlueJet.Balance.Card.Service, only: [create_card: 2]

  alias BlueJet.Balance.Payment
  alias BlueJet.Balance.Payment.{Query, Proxy}

  @spec list_payment(map, map) :: [Payment.t()]
  def list_payment(query \\ %{}, opts), do: default_list(Query, query, opts)

  @spec count_payment(map, map) :: integer
  def count_payment(query \\ %{}, opts), do: default_count(Query, query, opts)

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
      |> Multi.run(:payment, &Repo.insert(&1[:changeset]))
      |> Multi.run(:stripe_charge, &charge_payment(&1[:payment]))
      |> Multi.run(:processed_payment, fn %{payment: payment, changeset: changeset} ->
        Payment.process(payment, changeset)
      end)
      |> Multi.run(:after_create, fn %{processed_payment: payment} ->
        dispatch("balance.payment.create.success", %{payment: payment, account: account})
      end)

    case Repo.transaction(statements) do
      {:ok, %{processed_payment: payment}} ->
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
      owner = ensure_stripe_customer_id(owner)
      put_change(changeset, :stripe_customer_id, owner.id)
    else
      changeset
    end

    {:ok, changeset}
  end

  defp ensure_stripe_customer_id(%{stripe_customer_id: nil} = owner) do
    with {:ok, scustomer} <- Proxy.create_stripe_customer(owner),
         {:ok, owner} <- Proxy.update_owner(owner, %{stripe_customer_id: scustomer["id"]}) do
      {:ok, owner}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_stripe_customer_id(owner), do: owner

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
           # Card.keep_stripe_source(stripe_data, card_fields, %{account: payment.account}),
         {:ok, stripe_charge} <- Proxy.create_stripe_charge(payment, card.stripe_card_id, stripe_user_id) do
      sync_from_stripe_charge(payment, stripe_charge)
    else
      {:error, %{errors: _} = errors} ->
        {:error, errors}

      {:error, stripe_errors} ->
        {:error, format_stripe_errors(stripe_errors)}
    end

  end

  defp sync_from_stripe_charge(payment, stripe_charge) do
  end

  defp format_stripe_errors(%{} = stripe_errors) do
    %{errors: [source: {stripe_errors["error"]["message"], code: stripe_errors["error"]["code"]}]}
  end

  defp format_stripe_errors(stripe_errors), do: stripe_errors

  def get_payment(identifiers, opts) do
    get(Payment, identifiers, opts)
  end

  def update_payment(nil, _, _), do: {:error, :not_found}

  def update_payment(%Payment{} = payment, fields, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)

    changeset =
      %{payment | account: account}
      |> Payment.changeset(:update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.update(:payment, changeset)
      |> Multi.run(:processed_payment, fn %{payment: payment} ->
        Payment.process(payment, changeset)
      end)
      |> Multi.run(:after_update, fn %{processed_payment: payment} ->
        dispatch("balance.payment.update.success", %{payment: payment, account: account})
      end)

    case Repo.transaction(statements) do
      {:ok, %{processed_payment: payment}} ->
        payment = preload(payment, preloads[:path], preloads[:opts])
        {:ok, payment}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_payment(identifiers, fields, opts) do
    get_payment(identifiers, Map.merge(opts, %{preloads: %{}}))
    |> update_payment(fields, opts)
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