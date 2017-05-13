defmodule BlueJet.Jwt do
  use BlueJet.Web, :model

  alias BlueJet.User
  alias BlueJet.Account

  schema "jwts" do
    field :value, :string
    field :name, :string
    field :system_tag, :string

    field :email, :string, virtual: true
    field :password, :string, virtual: true

    timestamps()

    belongs_to :user, User
    belongs_to :account, Account
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :system_tag, :account_id, :user_id])
    |> validate_required([:name, :system_tag, :account_id])
    |> put_value
  end

  def sign_token(claims) do
    {_, signed} = System.get_env("JWT_PRIVATE_KEY")
                 |> JOSE.JWK.from_pem
                 |> JOSE.JWT.sign(%{ "alg" => "RS256" }, claims)
                 |> JOSE.JWS.compact
    signed
  end

  def verify_token(signed_token) do
    {true, %JOSE.JWT{ fields: claims }, _} = System.get_env("JWT_PUBLIC_KEY")
                                          |> JOSE.JWK.from_pem
                                          |> JOSE.JWT.verify_strict(["RS256"], signed_token)
    {true, claims}
  end

  defp put_value(changeset = %Ecto.Changeset{ valid?: valid? }) when valid? do
    signed_token = sign_token(%{ jti: Ecto.UUID.generate() })

    put_change(changeset, :value, signed_token)
  end
  defp put_value(changeset), do: changeset
end
