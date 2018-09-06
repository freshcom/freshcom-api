defmodule BlueJet do
  def context do
    quote do
      import BlueJet.Context.Default
      alias BlueJet.{ContextRequest, ContextResponse, Translation}
    end
  end

  def policy do
    quote do
      import BlueJet.Policy.AuthorizedRequest
      use BlueJet.Policy.Common
    end
  end

  def service do
    quote do
      import BlueJet.Service.{Option, Preload, Helper, Default}
      import BlueJet.Query
      alias BlueJet.Repo
    end
  end

  def data do
    quote do
      import Ecto
      import Ecto.Changeset
      import BlueJet.{Query, Validation}

      use Ecto.Schema

      alias Ecto.Changeset
      alias BlueJet.{Repo, Translation}

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
    end
  end

  def query do
    quote do
      import Ecto.Query
      import BlueJet.Query.Helper

      use BlueJet.Query.Preloads
    end
  end

  def proxy do
    quote do
      import BlueJet.Proxy.Option
      use BlueJet.Proxy.Common
      alias BlueJet.ContextRequest
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
