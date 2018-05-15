defmodule BlueJet.Balance.DefaultService do
  use BlueJet, :service
  use BlueJet.EventEmitter, namespace: :balance

  alias Ecto.Multi
  alias BlueJet.Balance.{Settings, Card, Payment, Refund}

  @behaviour BlueJet.Balance.Service

  #
  # MARK: Settings
  #
  def create_settings(opts) do
    account_id = extract_account_id(opts)

    %Settings{ account_id: account_id }
    |> Repo.insert()
  end

  def get_settings(opts) do
    account_id = extract_account_id(opts)

    Repo.get_by(Settings, account_id: account_id)
  end

  def update_settings(nil, _, _), do: {:error, :not_found}

  def update_settings(settings, fields, opts) do
    account = extract_account(opts)

    changeset =
      %{ settings | account: account }
      |> Settings.changeset(:update, fields)

    statements =
      Multi.new()
      |> Multi.update(:settings, changeset)
      |> Multi.run(:processed_settings, fn(%{ settings: settings }) ->
          Settings.process(settings, changeset)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_settings: settings }} ->
        {:ok, settings}

      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def update_settings(fields, opts) do
    account = extract_account(opts)
    opts = %{ opts | account: account }

    Settings
    |> Repo.get_by(account_id: account.id)
    |> update_settings(fields, opts)
  end

  def delete_settings(settings = %Settings{}, _) do
    with {:ok, settings} <- Repo.delete(settings) do
      {:ok, settings}
    else
      other -> other
    end
  end

  def delete_settings(opts) do
    account_id = extract_account_id(opts)

    settings = Repo.get_by(Settings, account_id: account_id)
    delete_settings(settings, opts)
  end

  #
  # MARK: Card
  #
  def list_card(fields \\ %{}, opts) do
    list(Card, fields, opts)
  end

  def count_card(fields \\ %{}, opts) do
    count(Card, fields, opts)
  end

  def update_card(nil, _, _), do: {:error, :not_found}

  def update_card(card = %Card{}, fields, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)

    changeset =
      %{ card | account: account }
      |> Card.changeset(:update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.update(:card, changeset)
      |> Multi.run(:processed_card, fn(%{ card: card }) ->
          Card.process(card, changeset)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_card: card }} ->
        card = preload(card, preloads[:path], preloads[:opts])
        {:ok, card}

      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def update_card(identifiers, fields, opts) do
    get(Card, identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> update_card(fields, opts)
  end

  def delete_card(nil, _), do: {:error, :not_found}

  def delete_card(card = %Card{}, opts) do
    account = extract_account(opts)

    changeset =
      %{ card | account: account }
      |> Card.changeset(:delete)

    statements =
      Multi.new()
      |> Multi.delete(:card, changeset)
      |> Multi.run(:processed_card, fn(%{ card: card }) ->
          Card.process(card, changeset)
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_card: card }} ->
        {:ok, card}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def delete_card(identifiers, opts) do
    get(Card, identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> delete_card(opts)
  end

  def delete_all_card(opts) do
    delete_all(Card, opts)
  end

  #
  # MARK: Payment
  #
  def list_payment(fields \\ %{}, opts) do
    list(Payment, fields, opts)
  end

  def count_payment(fields, opts) do
    count(Payment, fields, opts)
  end

  def create_payment(fields, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)

    changeset =
      %Payment{ account_id: account.id, account: account }
      |> Payment.changeset(:insert, fields)

    statements =
      Multi.new()
      |> Multi.run(:before_create, fn(_)->
          emit_event("balance.payment.create.before", %{ changeset: changeset })
         end)
      |> Multi.run(:changeset, fn(_) ->
          Payment.preprocess(changeset)
         end)
      |> Multi.run(:payment, fn(%{ changeset: changeset }) ->
          Repo.insert(changeset)
         end)
      |> Multi.run(:processed_payment, fn(%{ payment: payment, changeset: changeset }) ->
          Payment.process(payment, changeset)
         end)
      |> Multi.run(:after_create, fn(%{ processed_payment: payment }) ->
          emit_event("balance.payment.create.success", %{ payment: payment, account: account })
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_payment: payment }} ->
        payment = preload(payment, preloads[:path], preloads[:opts])
        {:ok, payment}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def get_payment(identifiers, opts) do
    get(Payment, identifiers, opts)
  end

  def update_payment(nil, _, _), do: {:error, :not_found}

  def update_payment(payment = %Payment{}, fields, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)

    changeset =
      %{ payment | account: account }
      |> Payment.changeset(:update, fields, opts[:locale])

    statements =
      Multi.new()
      |> Multi.update(:payment, changeset)
      |> Multi.run(:processed_payment, fn(%{ payment: payment }) ->
          Payment.process(payment, changeset)
         end)
      |> Multi.run(:after_update, fn(%{ processed_payment: payment }) ->
          emit_event("balance.payment.update.success", %{ payment: payment, account: account })
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_payment: payment }} ->
        payment = preload(payment, preloads[:path], preloads[:opts])
        {:ok, payment}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_payment(identifiers, fields, opts) do
    get_payment(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> update_payment(fields, opts)
  end

  def delete_payment(nil, _), do: {:error, :not_found}

  def delete_payment(payment = %Payment{}, opts) do
    delete(payment, opts)
  end

  def delete_payment(identifiers, opts) do
    get_payment(identifiers, Map.merge(opts, %{ preloads: %{} }))
    |> delete_payment(opts)
  end

  def delete_all_payment(opts) do
    delete_all(Payment, opts)
  end

  #
  # MARK: Refund
  #
  def create_refund(fields, opts) do
    account = extract_account(opts)
    preloads = extract_preloads(opts, account)

    changeset =
      %Refund{ account_id: account.id, account: account }
      |> Refund.changeset(:insert, fields)

    statements =
      Multi.new()
      |> Multi.insert(:refund, changeset)
      |> Multi.run(:processed_refund, fn(%{ refund: refund }) ->
          Refund.process(refund, changeset)
         end)
      |> Multi.run(:after_create, fn(%{ processed_refund: refund }) ->
          emit_event("balance.refund.create.success", %{ refund: refund })
          {:ok, refund}
         end)

    case Repo.transaction(statements) do
      {:ok, %{ processed_refund: refund }} ->
        refund = preload(refund, preloads[:path], preloads[:opts])
        {:ok, refund}

      {:error, _, changeset, _} ->
        {:error, changeset}

      other -> other
    end
  end
end