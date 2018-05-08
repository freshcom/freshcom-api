defmodule Mix.Tasks.BlueJet.Db.Sample do
  use Mix.Task
  import Mix.Ecto

  @shortdoc "Add initial account for alpha release"

  @moduledoc """
    This is where we would put any long form documentation or doctests.
  """

  def run(args) do
    alias BlueJet.Repo

    alias BlueJet.Identity
    alias BlueJet.AccessRequest

    Application.ensure_all_started(:blue_jet)
    # Application.ensure_all_started(:bamboo)

    {:ok, %{ data: user }} = Identity.create_user(%AccessRequest{
      fields: %{
        "first_name" => "Test",
        "last_name" => "User",
        "username" => "test@example.com",
        "email" => "test@example.com",
        "password" => "test1234",
        "account_name" => "Example Account",
        "default_locale" => "en"
      }
    })
  end
end