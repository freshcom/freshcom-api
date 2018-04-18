defmodule BlueJet.Balance.DefaultService do
  use BlueJet, :service
  use BlueJet.EventEmitter, namespace: :balance

  alias Ecto.Multi
  alias BlueJet.Balance.IdentityService
  alias BlueJet.Balance.{Settings, Card, Payment, Refund}

  @behaviour BlueJet.Balance.Service

  defp get_account(opts) do
    opts[:account] || IdentityService.get_account(opts)
  end

  defp get_account_id(opts) do
    opts[:account_id] || get_account(opts).id
  end

  defp put_account(opts) do
    %{ opts | account: get_account(opts) }
  end

  #
  # MARK: Settings
  #
  def create_settings(opts) do
    account_id = get_account_id(opts)

    %Settings{ account_id: account_id }
    |> Repo.insert()
  end

  def get_settings(opts) do
    account_id = get_account_id(opts)

    Repo.get_by(Settings, account_id: account_id)
  end

  def update_settings(nil, _, _), do: {:error, :not_found}

  def update_settings(settings, fields, opts) do
    account = get_account(opts)

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
    opts = put_account(opts)
    account = opts[:account]

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
    account_id = get_account_id(opts)

    settings = Repo.get_by(Settings, account_id: account_id)
    delete_settings(settings, opts)
  end

  #
  # MARK: Card
  #
  def list_card(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    Card.Query.default()
    |> Card.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Card.Query.filter_by(filter)
    |> Card.Query.for_account(account.id)
    |> Card.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_card(fields \\ %{}, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    Card.Query.default()
    |> Card.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Card.Query.filter_by(filter)
    |> Card.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  def update_card(nil, _, _), do: {:error, :not_found}

  def update_card(card = %Card{}, fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

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

  def update_card(id, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Card
    |> Repo.get_by(id: id, account_id: account.id)
    |> update_card(fields, opts)
  end

  def delete_card(nil, _), do: {:error, :not_found}

  def delete_card(card = %Card{}, opts) do
    account = get_account(opts)

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

  def delete_card(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Card
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_card(opts)
  end

  def delete_all_card(opts = %{ account: account = %{ mode: "test" } }) do
    batch_size = opts[:batch_size] || 1000

    card_ids =
      Card.Query.default()
      |> Card.Query.for_account(account.id)
      |> Card.Query.paginate(size: batch_size, number: 1)
      |> Card.Query.id_only()
      |> Repo.all()

    Card.Query.default()
    |> Card.Query.filter_by(%{ id: card_ids })
    |> Repo.delete_all()

    if length(card_ids) === batch_size do
      delete_all_card(opts)
    else
      :ok
    end
  end

  #
  # MARK: Payment
  #
  def list_payment(fields \\ %{}, opts) do
    account = get_account(opts)
    pagination = get_pagination(opts)
    preloads = get_preloads(opts, account)
    filter = get_filter(fields)

    Payment.Query.default()
    |> Payment.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Payment.Query.filter_by(filter)
    |> Payment.Query.for_account(account.id)
    |> Payment.Query.paginate(size: pagination[:size], number: pagination[:number])
    |> Repo.all()
    |> preload(preloads[:path], preloads[:opts])
  end

  def count_payment(fields, opts) do
    account = get_account(opts)
    filter = get_filter(fields)

    Payment.Query.default()
    |> Payment.Query.search(fields[:search], opts[:locale], account.default_locale)
    |> Payment.Query.filter_by(filter)
    |> Payment.Query.for_account(account.id)
    |> Repo.aggregate(:count, :id)
  end

  defp run_before_create_payment(fields) do
    with {:ok, results} <- emit_event("balance.payment.create.before", %{ fields: fields }) do
      values = [fields] ++ Keyword.values(results)
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

  def create_payment(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    changeset =
      %Payment{ account_id: account.id, account: account }
      |> Payment.changeset(:insert, fields)

    statements =
      Multi.new()
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

  def get_payment(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

    Payment.Query.default()
    |> Payment.Query.for_account(account.id)
    |> Repo.get_by(fields)
    |> preload(preloads[:path], preloads[:opts])
  end

  def update_payment(nil, _, _), do: {:error, :not_found}

  def update_payment(payment = %Payment{}, fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

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

  def update_payment(id, fields, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Payment
    |> Repo.get_by(id: id, account_id: account.id)
    |> update_payment(fields, opts)
  end

  def delete_payment(nil, _), do: {:error, :not_found}

  def delete_payment(payment = %Payment{}, opts) do
    account = get_account(opts)

    changeset =
      %{ payment | account: account }
      |> Payment.changeset(:delete)

    with {:ok, payment} <- Repo.delete(changeset) do
      {:ok, payment}
    else
      other -> other
    end
  end

  def delete_payment(id, opts) do
    opts = put_account(opts)
    account = opts[:account]

    Payment
    |> Repo.get_by(id: id, account_id: account.id)
    |> delete_payment(opts)
  end

  def delete_all_payment(opts = %{ account: account = %{ mode: "test" } }) do
    batch_size = opts[:batch_size] || 1000

    payment_ids =
      Payment.Query.default()
      |> Payment.Query.for_account(account.id)
      |> Payment.Query.paginate(size: batch_size, number: 1)
      |> Payment.Query.id_only()
      |> Repo.all()

    Payment.Query.default()
    |> Payment.Query.filter_by(%{ id: payment_ids })
    |> Repo.delete_all()

    if length(payment_ids) === batch_size do
      delete_all_payment(opts)
    else
      :ok
    end
  end

  #
  # MARK: Refund
  #
  def create_refund(fields, opts) do
    account = get_account(opts)
    preloads = get_preloads(opts, account)

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