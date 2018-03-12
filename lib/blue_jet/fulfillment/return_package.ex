defmodule BlueJet.Fulfillment.ReturnPackage do
  @moduledoc """
  """
  use BlueJet, :data

  use Trans, translates: [
    :name,
    :caption,
    :description,
    :custom_data
  ], container: :translations

  alias __MODULE__.Proxy
  alias BlueJet.Fulfillment.ReturnItem

  schema "return_packages" do
    field :account_id, Ecto.UUID
    field :account, :map, virtual: true

    field :system_label, :string

    # pending, in_progress, partially_returned, returned
    field :status, :string, default: "pending"
    field :code, :string
    field :name, :string
    field :label, :string

    field :caption, :string
    field :description, :string
    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    field :order_id, Ecto.UUID
    field :order, :map, virtual: true

    field :customer_id, Ecto.UUID
    field :customer, :map, virtual: true

    field :file_collections, {:array, :map}, default: [], virtual: true

    timestamps()

    has_many :items, ReturnItem, foreign_key: :package_id
  end

  @type t :: Ecto.Schema.t

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

  def validate_status(changeset = %{
    data: %{ status: "pending" },
    changes: %{ status: status }
  }) when status != "in_progress" do
    add_error(changeset, :status, "is invalid", validation: :must_be_in_progress)
  end

  def validate_status(changeset = %{
    data: %{ status: "in_progress" },
    changes: %{ status: status }
  }) when status != "pending" do
    add_error(changeset, :status, "is invalid", validation: :must_be_pending)
  end

  def validate_status(changeset = %{
    data: %{ status: status },
    changes: %{ status: _ }
  }) when status not in ["pending", "in_progress"] do
    add_error(changeset, :status, "is not changeable", validation: :unchangeable)
  end

  def validate_status(changeset), do: changeset

  def validate(changeset = %{ action: :insert }) do
    changeset
    |> validate_required([:order_id])
    |> validate_inclusion(:status, ["pending", "in_progress"])
  end

  def validate(changeset = %{ action: :update }) do
    changeset
    |> validate_status()
  end

  def validate(changeset = %{ action: :delete }) do
    changeset
    |> validate_inclusion(:status, ["pending", "in_progress"])
  end

  def validate(changeset), do: changeset

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(return_package, :insert, params) do
    return_package
    |> cast(params, writable_fields())
    |> Map.put(:action, :insert)
    |> validate()
  end

  def changeset(return_package, :update, params, locale \\ nil, default_locale \\ nil) do
    return_package = Proxy.put_account(return_package)
    default_locale = default_locale || return_package.account.default_locale
    locale = locale || default_locale

    return_package
    |> cast(params, writable_fields())
    |> Map.put(:action, :update)
    |> validate()
    |> Translation.put_change(translatable_fields(), locale, default_locale)
  end

  def changeset(return_package, :delete) do
    return_package
    |> Map.put(:action, :delete)
    |> validate()
  end

  def get_status(return_package) do
    return_package = Repo.preload(return_package, :items)
    items = return_package.items

    pending_count = Enum.reduce(items, 0, fn(item, acc) ->
      if item.status in ["pending", "in_progress"], do: acc + 1, else: acc
    end)

    returned_count = Enum.reduce(items, 0, fn(item, acc) ->
      if item.status == "returned", do: acc + 1, else: acc
    end)

    cond do
      returned_count == 0 ->
        if return_package.status in ["pending", "in_progress"], do: return_package.status, else: "pending"

      (returned_count > 0) && (pending_count == 0) ->
        "returned"

      pending_count > 0 ->
        "partially_returned"
    end
  end
end
