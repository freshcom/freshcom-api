defmodule BlueJet.Router do
  use BlueJet.Web, :router

  def verify_content_type(%Plug.Conn{method: "OPTIONS"} = conn, _o), do: conn

  pipeline :api do
    plug :accepts, ["json-api"]
    plug BlueJet.CORS
    plug JaSerializer.ContentTypeNegotiation
    plug JaSerializer.Deserializer
  end

  scope "/", BlueJet do
    pipe_through :api

    options "/*path", WelcomeController, :options

    resources "/products", ProductController, except: [:new, :edit]
    resources "/skus", SkuController, except: [:new, :edit]
  end
end
