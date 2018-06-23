defmodule BlueJet.Identity.PhoneVerificationCode do
  use BlueJet, :data

  alias BlueJet.Identity.Account
  alias __MODULE__.Query

  schema "phone_verification_codes" do
    field :phone_number, :string
    field :value, :string
    field :expires_at, :utc_datetime

    timestamps()

    belongs_to :account, Account
  end

  @type t :: Ecto.Schema.t

  @spec changeset(__MODULE__.t(), atom, map) :: Changeset.t()
  def changeset(pvc, :insert, params) do
    pvc
    |> cast(params, [:phone_number])
    |> Map.put(:action, :insert)
    |> validate()
    |> put_value()
    |> put_expires_at()
  end

  defp generate_value(n, account_id) do
    value = Enum.reduce(1..n, "", fn(_, acc) ->
      char = Enum.random(0..9)
      acc <> Integer.to_string(char)
    end)

    if Repo.get_by(__MODULE__, value: value, account_id: account_id) do
      generate_value(n, account_id)
    else
      value
    end
  end

  defp put_value(changeset = %{ valid?: true }) do
    account = get_field(changeset, :account)
    value = generate_value(6, account.id)
    put_change(changeset, :value, value)
  end

  defp put_value(changeset), do: changeset

  defp put_expires_at(changeset = %{ valid?: true }) do
    put_change(changeset, :expires_at, Timex.shift(Timex.now(), minutes: 30))
  end

  defp put_expires_at(changeset), do: changeset

  defp validate(changeset) do
    changeset
    |> validate_required(:phone_number)
    |> validate_length(:phone_number, min: 9)
    |> validate_format(:phone_number, Application.get_env(:blue_jet, :phone_regex))
  end

  def exists?(value, phone_number) do
    count =
      Query.default()
      |> Query.filter_by(%{ value: value, phone_number: phone_number })
      |> Repo.aggregate(:count, :id)

    count > 0
  end
end
