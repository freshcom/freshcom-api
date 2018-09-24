defmodule BlueJet do
  def context do
    quote do
      import BlueJet.Context
      alias BlueJet.{ContextRequest, ContextResponse, Translation}
    end
  end

  def policy do
    quote do
      use BlueJet.Policy.Common

      import BlueJet.Policy.AuthorizedRequest

      alias BlueJet.ContextRequest
    end
  end

  def service do
    quote do
      import Ecto.Changeset
      import BlueJet.Service.{Preload, Default}
      import BlueJet.Query
      import BlueJet.EventBus

      alias BlueJet.Repo
      alias Ecto.Multi
    end
  end

  def data do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import BlueJet.{Query, Validation}

      alias Ecto.{Changeset, UUID}
      alias BlueJet.{Repo, Translation}

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
    end
  end

  def query do
    quote do
      use BlueJet.Query.Preloads

      import Ecto.Query
      import BlueJet.Query
      import BlueJet.Query.Helper
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
