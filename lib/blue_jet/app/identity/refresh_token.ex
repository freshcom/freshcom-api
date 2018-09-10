defmodule BlueJet.Identity.RefreshToken do
  @moduledoc """
  Provides function related to Refresh Token.

  Refresh Token is long lived token that the client use to get a new Access Token.
  Refresh Token can be revoked easily in case it is compromised. Refresh Token
  can be obtained using Resource Owner's credential or from the Freshcom Dashboard.

  There is two types of Refresh Token:
  - Publishable Refresh Token
  - User Refresh Token

  Refresh Token with `user_id` set to `nil` is considered a Publishable Refresh Token and
  it never epxires.

  Refresh Token with `user_id` set to a specific User's ID is considered a User Refresh Token
  and by default it expires in 2 weeks.
  """
  use BlueJet, :data

  alias BlueJet.Identity.{Account, User}

  schema "refresh_tokens" do
    field :email, :string, virtual: true
    field :password, :string, virtual: true

    field :prefixed_id, :string, virtual: true

    timestamps()

    belongs_to :account, Account
    belongs_to :user, User
  end

  @type t :: Ecto.Schema.t()

  @spec changeset(__MODULE__.t(), atom, map) :: Changeset.t()
  def changeset(refresh_token, :insert, params) do
    refresh_token
    |> cast(params, [:user_id])
    |> Map.put(:action, :insert)
  end

  def get_prefixed_id(refresh_token = %{id: id, user_id: nil}) do
    refresh_token = Repo.preload(refresh_token, :account)
    mode = refresh_token.account.mode
    "prt-#{mode}-#{id}"
  end

  def get_prefixed_id(refresh_token = %{id: id}) do
    refresh_token = Repo.preload(refresh_token, :account)
    mode = refresh_token.account.mode
    "urt-#{mode}-#{id}"
  end

  def put_prefixed_id(refresh_token) do
    %{refresh_token | prefixed_id: get_prefixed_id(refresh_token)}
  end

  def unprefix_id(id) do
    id
    |> String.replace_prefix("prt-test-", "")
    |> String.replace_prefix("prt-live-", "")
    |> String.replace_prefix("urt-test-", "")
    |> String.replace_prefix("urt-live-", "")
  end

  defmodule Query do
    import Ecto.Query
    alias BlueJet.Identity.RefreshToken

    def default() do
      from(rt in RefreshToken)
    end

    def for_user(user_id) do
      from(rt in RefreshToken, where: rt.user_id == ^user_id)
    end

    def for_account(query, account_id) do
      from(rt in query, where: rt.account_id == ^account_id)
    end

    def publishable() do
      from(rt in RefreshToken, where: is_nil(rt.user_id))
    end
  end
end
