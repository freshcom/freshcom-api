defmodule BlueJetWeb.Router do
  use BlueJetWeb, :router

  pipeline :api do
    plug :accepts, ["json-api"]
    plug BlueJet.Plugs.CORS
    plug BlueJet.Plugs.Authentication, ["/v1/token"]
    plug BlueJet.Plugs.Locale, "en"
    plug BlueJet.Plugs.Pagination
    plug BlueJet.Plugs.Fields
    plug BlueJet.Plugs.Filter, default: %{}
    plug BlueJet.Plugs.Include, default: []
    plug BlueJet.Plugs.ContentTypeNegotiation
    plug JaSerializer.Deserializer
  end

  scope "/v1/", BlueJetWeb do
    pipe_through :api

    options "/*path", WelcomeController, :options

    resources "/token", TokenController, only: [:create]

    ####
    # Identity
    ####
    resources "/accounts", AccountController, except: [:new, :edit]
    resources "/members", AccountMemberController, except: [:new, :edit]
    resources "/users", UserController, except: [:new, :edit]

    ####
    # File Storage
    ####
    resources "/external_files", ExternalFileController, except: [:new, :edit]
    resources "/external_file_collections", ExternalFileCollectionController, except: [:new, :edit] do
      resources "/memberships", ExternalFileCollectionMembershipController, only: [:create]
    end
    resources "/external_file_collection_memberships", ExternalFileCollectionMembershipController, only: [:index, :update, :delete]

    #####
    # Inventory
    #####
    resources "/skus", SkuController, except: [:new, :edit]
    resources "/unlockables", UnlockableController, except: [:new, :edit]

    #####
    # Storefront
    #####
    resources "/customers", CustomerController, except: [:new, :edit]
    get "/customer", CustomerController, :show

    resources "/products", ProductController, except: [:new, :edit] do
      resources "/items", ProductItemController, only: [:create]
    end
    resources "/product_items", ProductItemController, except: [:new, :edit, :create] do
      resources "/prices", PriceController, only: [:create]
    end
    resources "/prices", PriceController, except: [:new, :edit, :create]
    resources "/orders", OrderController, except: [:new, :edit]
  end
end
