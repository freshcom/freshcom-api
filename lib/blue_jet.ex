defmodule BlueJet do
  def context do
    quote do
      import BlueJet.Context.Default
      alias BlueJet.{AccessRequest, AccessResponse, Translation}
    end
  end

  def service do
    quote do
      import BlueJet.Service.{Option, Preload, Helper, Default}
      alias BlueJet.Repo
    end
  end

  def data do
    quote do
      import Ecto
      import Ecto.{Changeset, Query}
      import BlueJet.Validation

      use Ecto.Schema

      alias BlueJet.{Repo, Translation}

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
    end
  end

  def query do
    quote do
      import Ecto.Query
      import BlueJet.Query.{Search, Helper}

      use BlueJet.Query.Common
      use BlueJet.Query.Preloads
    end
  end

  def proxy do
    quote do
      import BlueJet.Proxy.Option
      use BlueJet.Proxy.Common
      alias BlueJet.AccessRequest
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
