defmodule BlueJet.RefreshToken do
  use BlueJet.Web, :model

  alias BlueJet.User
  alias BlueJet.Customer
  alias BlueJet.Account

  schema "refresh_tokens" do
    field :email, :string, virtual: true
    field :password, :string, virtual: true

    timestamps()

    belongs_to :user, User
    belongs_to :customer, Customer
    belongs_to :account, Account
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:account_id, :user_id, :customer_id])
    |> validate_required([:account_id])
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
end
