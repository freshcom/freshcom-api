defmodule BlueJet.Router do
  use BlueJet.Web, :router

  pipeline :api do
    plug :accepts, ["json-api"]
    plug BlueJet.Plugs.CORS
    plug BlueJet.Plugs.Locale, "en"
    plug BlueJet.Plugs.Pagination
    plug BlueJet.Plugs.Fields
    plug JaSerializer.ContentTypeNegotiation
    plug JaSerializer.Deserializer
  end

  scope "/", BlueJet do
    pipe_through :api

    options "/*path", WelcomeController, :options

    resources "/products", ProductController, except: [:new, :edit]
    resources "/skus", SkuController, except: [:new, :edit]
    resources "/external_files", ExternalFileController, except: [:new, :edit]

    resources "/external_file_collections", ExternalFileCollectionController, except: [:new, :edit] do
      post "/relationships/files", ExternalFileCollectionController, :add_files
      patch "/relationships/files", ExternalFileCollectionController, :replace_files
    end
  end
end
