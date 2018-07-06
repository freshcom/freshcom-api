defmodule BlueJet.EventHandlerCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias BlueJet.Repo

      import Mox
      import BlueJet.EventHandlerCase

      setup :verify_on_exit!
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(BlueJet.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(BlueJet.Repo, {:shared, self()})
    end

    :ok
  end

  @doc """
  A helper that transform changeset errors to a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
