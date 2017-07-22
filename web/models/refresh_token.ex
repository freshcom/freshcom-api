defmodule BlueJet.RefreshToken do
  use BlueJet.Web, :model

  schema "refresh_tokens" do
    field :email, :string, virtual: true
    field :password, :string, virtual: true

    timestamps()

    belongs_to :account, BlueJet.Account
    belongs_to :customer, BlueJet.Customer
    belongs_to :user, BlueJet.User
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:account_id, :user_id, :customer_id])
    |> validate_required([:account_id])
    |> foreign_key_constraint(:account_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:customer_id)
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
