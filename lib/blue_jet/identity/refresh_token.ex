defmodule BlueJet.Identity.RefreshToken do
  @moduledoc """
  Provides function related to Refresh Token.

  Refresh Token are long lived token that the client use to get a new Access Token.
  Refresh Token can be revoked easily in case it is compromised. Refresh Token
  can be obtained using Resource Owner's credential or from the FreshCom Dashboard.

  There is two types of Refresh Token:
  - Storefront Refresh Token
  - User Refresh Token

  Refresh Token with `user_id` set to `nil` is considered a Storefront Refresh Token and
  it never epxires.

  Refresh Token with `user_id` set to a specific User's ID is considered a User Refresh Token
  and by default it expires in 2 weeks.
  """
  use BlueJet, :data

  alias BlueJet.Repo
  alias BlueJet.Identity.User
  alias BlueJet.Identity.RefreshToken
  alias BlueJet.Identity.Account

  schema "refresh_tokens" do
    field :email, :string, virtual: true
    field :password, :string, virtual: true

    field :prefixed_id, :string, virtual: true
    timestamps()

    belongs_to :account, Account
    belongs_to :user, User
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:account_id, :user_id])
    |> foreign_key_constraint(:account_id)
    |> foreign_key_constraint(:user_id)
  end

  def prefix_id(refresh_token = %{ id: id, user_id: nil }) do
    refresh_token = Repo.preload(refresh_token, :account)
    mode = refresh_token.account.mode
    "prt-#{mode}-#{id}"
  end
  def prefix_id(refresh_token = %{ id: id }) do
    refresh_token = Repo.preload(refresh_token, :account)
    mode = refresh_token.account.mode
    "urt-#{mode}-#{id}"
  end

  def unprefix_id(id) do
    id
    |> String.replace_prefix("prt-test-", "")
    |> String.replace_prefix("prt-live-", "")
    |> String.replace_prefix("urt-test-", "")
    |> String.replace_prefix("urt-live-", "")
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

  defmodule Query do
    def for_user(user_id) do
      from(rt in RefreshToken, where: rt.user_id == ^user_id)
    end

    def publishable() do
      from(rt in RefreshToken, where: is_nil(rt.user_id))
    end

    def default() do
      from(rt in RefreshToken, order_by: [desc: :inserted_at])
    end
  end
end
