defmodule BlueJet.Distribution.FulfillmentLineItem do
  @moduledoc """
  """
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :print_name,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias BlueJet.Distribution.{GoodsService, CrmService}
  alias BlueJet.Distribution.{Fulfillment, Unlock}
  alias BlueJet.Distribution.FulfillmentLineItem.Proxy

  schema "fulfillment_line_items" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :status, :string, default: "pending"
    field :code, :string
    field :name, :string
    field :label, :string

    field :quantity, :integer
    field :print_name, :string

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :order_line_item_id, Ecto.UUID
    field :order_line_item, :map, virtual: true

    field :target_id, Ecto.UUID
    field :target_type, :string
    field :target, :map, virtual: true

    field :source_id, Ecto.UUID
    field :source_type, :string
    field :source, :map, virtual: true

    field :file_collections, {:array, :map}, default: [], virtual: true

    timestamps()

    belongs_to :fulfillment, Fulfillment
  end

  @system_fields [
    :id,
    :account_id,
    :inserted_at,
    :updated_at
  ]

  def writable_fields do
    __MODULE__.__schema__(:fields) -- @system_fields
  end

  def translatable_fields do
    __MODULE__.__trans__(:fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required([:order_line_item_id])
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(fli, :insert, params) do
    fli
    |> cast(params, writable_fields())
    |> Map.put(:action, :insert)
    |> validate()
  end

  def changeset(fli, :update, params, locale \\ nil, default_locale \\ nil) do
    fli = Proxy.put_account(fli)
    default_locale = default_locale || fli.account.default_locale
    locale = locale || default_locale

    fli
    |> cast(params, writable_fields())
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  defp fulfill_unlockable(unlockable_id, customer_id, opts) do
    unlock =
      %Unlock{ account_id: opts[:account].id, account: opts[:account] }
      |> change(%{
          unlockable_id: unlockable_id,
          customer_id: customer_id
         })
      |> Repo.insert!()

    {:ok, unlock}
  end

  defp fulfill_depositable(depositable_id, quantity, customer_id, opts) do
    depositable = GoodsService.get_depositable(%{ id: depositable_id }, opts)
    point_account = CrmService.get_point_account(%{ customer_id: customer_id }, opts)
    CrmService.create_point_transaction(%{
      point_account_id: point_account.id,
      status: "committed",
      amount: quantity * depositable.amount,
      reason_label: "deposit_by_depositable"
    }, opts)
  end

  defp fulfill_point_transaction(pt_id, opts) do
    CrmService.update_point_transaction(pt_id, %{ status: "committed" }, opts)
  end

  def preprocess(changeset = %{
    data: %{
      fulfillment: %{ customer_id: customer_id },
      account: account
    },
    changes: %{
      status: "fulfilled",
      target_type: "Unlockable",
      target_id: unlockable_id
    }
  }) do
    opts = %{ account: account }

    {:ok, unlock} = fulfill_unlockable(unlockable_id, customer_id, opts)

    changeset =
      changeset
      |> put_change(:source_type, "Unlock")
      |> put_change(:source_id, unlock.id)

    {:ok, changeset}
  end

  def preprocess(changeset = %{
    data: %{
      fulfillment: %{ customer_id: customer_id },
      account: account
    },
    changes: %{
      status: "fulfilled",
      target_type: "Depositable",
      target_id: depositable_id,
      quantity: quantity
    }
  }) do
    opts = %{ account: account }
    case fulfill_depositable(depositable_id, quantity, customer_id, opts) do
      {:ok, nil} ->
        {:ok, changeset}

      {:ok, point_transaction} ->
        changeset =
          changeset
          |> put_change(:source_type, "PointTransaction")
          |> put_change(:source_id, point_transaction.id)
        {:ok, changeset}

      other -> other
    end
  end

  def preprocess(changeset = %{
    data: %{
      account: account
    },
    changes: %{
      status: "fulfilled",
      target_type: "PointTransaction",
      target_id: point_transaction_id
    }
  }) do
    opts = %{ account: account }

    case fulfill_point_transaction(point_transaction_id, opts) do
      {:ok, point_transaction} ->
        changeset =
          changeset
          |> put_change(:source_type, "PointTransaction")
          |> put_change(:source_id, point_transaction.id)
        {:ok, changeset}

      other -> other
    end
  end

  def preprocess(changeset = %{
      data: data,
      changes: %{ status: "fulfilled" }
    }
  ) do
    data = Repo.preload(data, :fulfillment)
    changeset = %{ changeset | data: data }

    preprocess(changeset)
  end

  def preprocess(changeset = %{
    data: %{
      source_type: "Unlock",
      source_id: unlock_id
    },
    changes: %{
      status: "returned"
    }
  }) do
    Repo.get!(Unlock, unlock_id)
    |> Repo.delete!()

    changeset =
      changeset
      |> put_change(:source_type, nil)
      |> put_change(:source_id, nil)

    {:ok, changeset}
  end
end
