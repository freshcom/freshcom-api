defmodule BlueJetWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use BlueJetWeb, :controller
      use BlueJetWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def model do
    quote do
      use Ecto.Schema

      # import Ecto
      import Ecto.Changeset
      # import Ecto.Query

      # import BlueJet.Validation

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, namespace: BlueJetWeb
      import Plug.Conn
      import BlueJetWeb.Router.Helpers
      import BlueJetWeb.Gettext
      ########

      alias BlueJet.Repo
      alias BlueJet.Translation

      import BlueJetWeb.Controller.Helpers
      alias BlueJet.AccessRequest
      alias BlueJet.AccessResponse
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
      # use Phoenix.View, root: "web/templates"
      use Phoenix.View, root: "lib/blue_jet_web/templates",
                        namespace: BlueJetWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 2, view_module: 1]

      import BlueJetWeb.Router.Helpers
      import BlueJetWeb.ErrorHelpers
      import BlueJetWeb.Gettext
      ########

      alias BlueJet.Translation
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import BlueJetWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
