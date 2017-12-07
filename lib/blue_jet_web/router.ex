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
    get "/account", AccountController, :show
    patch "/account", AccountController, :update
    resources "/members", AccountMemberController, except: [:new, :edit]
    resources "/users", UserController, except: [:new, :edit]
    get "/user", UserController, :show

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

    #####
    # Storefront
    #####
    resources "/customers", CustomerController, except: [:new, :edit]
    get "/customer", CustomerController, :show

    resources "/products", ProductController, except: [:new, :edit] do
      resources "/items", ProductItemController, only: [:create]
    end
    resources "/product_items", ProductItemController, except: [:new, :edit]
    resources "/prices", PriceController, except: [:new, :edit]
    resources "/orders", OrderController, except: [:new, :edit] do
      resources "/line_items", OrderLineItemController, only: [:create]
    end
    resources "/order_line_items", OrderLineItemController, only: [:update, :delete]

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
