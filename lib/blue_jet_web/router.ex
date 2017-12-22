defmodule BlueJetWeb.Router do
  use BlueJetWeb, :router

  pipeline :api do
    plug :accepts, ["json-api"]
    plug BlueJet.Plugs.CORS
    plug BlueJet.Plugs.Authentication, ["/v1/token"]
    plug BlueJet.Plugs.Locale, nil
    plug BlueJet.Plugs.Pagination
    plug BlueJet.Plugs.Fields
    plug BlueJet.Plugs.Filter, default: %{}
    plug BlueJet.Plugs.Include, default: []
    plug BlueJet.Plugs.ContentTypeNegotiation
    plug JaSerializer.Deserializer
  end

  get "/", BlueJetWeb.WelcomeController, :index

  scope "/v1/", BlueJetWeb do
    pipe_through :api

    options "/*path", WelcomeController, :options

    resources "/token", TokenController, only: [:create]

    ####
    # Identity
    ####
    resources "/accounts", AccountController, except: [:new, :edit]
    get "/account", AccountController, :show
    patch "/account", AccountController, :update
    resources "/members", AccountMemberController, except: [:new, :edit]
    resources "/users", UserController, except: [:new, :edit]
    get "/user", UserController, :show
    get "/refresh_token", RefreshTokenController, :show

    ####
    # File Storage
    ####
    resources "/external_files", ExternalFileController, except: [:new, :edit]
    resources "/external_file_collections", ExternalFileCollectionController, except: [:new, :edit]
    # resources "/external_file_collection_memberships", ExternalFileCollectionMembershipController, only: [:index, :update, :delete]

    #####
    # Goods
    #####
    resources "/stockables", StockableController, except: [:new, :edit]
    resources "/unlockables", UnlockableController, except: [:new, :edit]
    resources "/depositables", DepositableController, except: [:new, :edit]

    #
    # CRM
    #
    resources "/customers", CustomerController, except: [:new, :edit]
    get "/customer", CustomerController, :show
    resources "/point_transactions", PointTransactionController, only: [:create, :show, :delete]

    #
    # Catalogue
    #
    resources "/products", ProductController, except: [:new, :edit]
    resources "/prices", PriceController, except: [:new, :edit]
    get "/product_collection", ProductCollectionController, :show
    resources "/product_collections", ProductCollectionController, except: [:new, :edit] do
      resources "/memberships", ProductCollectionMembershipController, only: [:index, :create]
    end
    resources "/product_collection_memberships", ProductCollectionMembershipController, only: [:show, :update, :delete]

    #####
    # Storefront
    #####
    resources "/orders", OrderController, except: [:new, :edit] do
      resources "/line_items", OrderLineItemController, only: [:create]
    end
    resources "/order_line_items", OrderLineItemController, only: [:index, :update, :delete]
    resources "/unlocks", UnlockController, only: [:show, :index]

    #####
    # Billing
    #####
    resources "/cards", CardController, only: [:index, :create, :update, :delete]
    resources "/payments", PaymentController do
      resources "/refunds", RefundController, only: [:create]
    end

    get "/billing_settings", BillingSettingsController, :show
    patch "/billing_settings", BillingSettingsController, :update

    ####
    # Data Trading
    ####
    resources "/data_imports", DataImportController, only: [:index, :create, :show, :delete]
  end
end
