defmodule Mix.Tasks.BlueJet.Db.Sample do
  use Mix.Task
  import Mix.Ecto

  @shortdoc "Add sample data to db"

  @moduledoc """
    This is where we would put any long form documentation or doctests.
  """

  def run(args) do
    Mix.Tasks.Ecto.Drop.run(args)
    Mix.Tasks.Ecto.Create.run(args)
    Mix.Tasks.Ecto.Migrate.run(args)

    alias BlueJet.Repo
    alias BlueJet.Sku

    ensure_started(Repo, [])

    Repo.insert!(%Sku{
      number: "HS001",
      status: "active",
      name: "新经销商培训",
      print_name: "HS001",
      unit_of_measure: "ea",
      stackable: true
    })
  end

  # We can define other functions as needed here.
end