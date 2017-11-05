defmodule BlueJet do
  @moduledoc """
  BlueJet keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def context do
    quote do
      alias BlueJet.Repo
      alias BlueJet.Translation
      alias BlueJet.AccessRequest
      alias BlueJet.AccessResponse

      import Ecto
      import Ecto.Query

      import BlueJet.ContextHelpers
    end
  end

  def data do
    quote do
      use Ecto.Schema
      import Ecto.Changeset

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      #######

      import Ecto
      import Ecto.Query
      import BlueJet.Validation
      alias BlueJet.Repo
      alias BlueJet.Translation
    end
  end

  def query do
    quote do
      def preloads(targets) when is_list(targets) and length(targets) == 0 do
        []
      end
      def preloads(targets) when is_list(targets) do
        [target | rest] = targets
        preloads(target) ++ preloads(rest)
      end
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
