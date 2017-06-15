defmodule BlueJet.Web do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use BlueJet.Web, :controller
      use BlueJet.Web, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def model do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
    end
  end

  def controller do
    quote do
      use Phoenix.Controller

      alias BlueJet.Repo
      alias BlueJet.Translation

      import Ecto
      import Ecto.Query

      import BlueJet.Router.Helpers
      import BlueJet.Gettext

      import BlueJet.Controller.Helpers
      # def paginate(query, %{ number: number, size: size }) do
      #   limit = size
      #   offset = size * (number - 1)

      #   query
      #   |> limit(^limit)
      #   |> offset(^offset)
      # end
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "web/templates"

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      import BlueJet.Router.Helpers
      import BlueJet.ErrorHelpers
      import BlueJet.Gettext
    end
  end

  def router do
    quote do
      use Phoenix.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel

      alias BlueJet.Repo
      import Ecto
      import Ecto.Query
      import BlueJet.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
