defmodule BlueJet.Router do
  use BlueJet.Web, :router

  pipeline :api do
    plug :accepts, ["json-api"]
    plug BlueJet.Plugs.CORS
    plug BlueJet.Plugs.Locale, "en"
    plug BlueJet.Plugs.Pagination
    plug JaSerializer.ContentTypeNegotiation
    plug JaSerializer.Deserializer
  end

  scope "/", BlueJet do
    pipe_through :api

    options "/*path", WelcomeController, :options

    resources "/products", ProductController, except: [:new, :edit]
    resources "/skus", SkuController, except: [:new, :edit]
    resources "/s3_files", S3FileController, except: [:new, :edit]
    resources "/s3_file_sets", S3FileSetController, except: [:new, :edit]
  end
end
