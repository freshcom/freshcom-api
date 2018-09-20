defmodule BlueJetWeb.Router do
  use BlueJetWeb, :router
  use Plug.ErrorHandler
  use Sentry.Plug

  pipeline :api do
    plug :accepts, ["json-api"]
    plug BlueJet.Plugs.CORS
    plug BlueJet.Plugs.Authentication, ["/v1/token", "/v1/users", "/v1/password_reset_tokens", "/v1/email_verifications", "/v1/password"]
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

    #
    # MARK: Identity
    #
    resources "/token", TokenController, only: [:create]

    get "/account", AccountController, :show
    patch "/account", AccountController, :update
    post "/account_resets", AccountResetController, :create

    resources "/account_memberships", AccountMembershipController, only: [:index, :update]

    resources "/members", AccountMemberController, except: [:new, :edit]
    resources "/users", UserController, only: [:create, :show, :update, :delete]

    get "/user", UserController, :show
    patch "/user", UserController, :update

    get "/refresh_token", RefreshTokenController, :show

    post "/password_reset_tokens", PasswordResetTokenController, :create
    resources "/passwords", PasswordController, only: [:update]
    patch "/password", PasswordController, :update
    post "/email_verification_tokens", EmailVerificationTokenController, :create
    post "/email_verifications", EmailVerificationController, :create
    post "/phone_verification_codes", PhoneVerificationCodeController, :create

    ####
    # File Storage
    ####
    resources "/files", FileController, except: [:new, :edit]
    resources "/file_collections", FileCollectionController, except: [:new, :edit] do
      resources "/memberships", FileCollectionMembershipController, only: [:index, :create]
    end
    resources "/file_collection_memberships", FileCollectionMembershipController, only: [:show, :delete, :update]

    #####
    # Goods
    #####
    resources "/stockables", StockableController, except: [:new, :edit]
    resources "/unlockables", UnlockableController, except: [:new, :edit]
    resources "/depositables", DepositableController, except: [:new, :edit]

    #
    # Crm
    #
    resources "/customers", CustomerController, except: [:new, :edit]
    get "/customer", CustomerController, :show
    resources "/point_accounts", PointAccountController, only: [:show] do
      resources "/transactions", PointTransactionController, only: [:create, :index]
    end
    resources "/point_transactions", PointTransactionController, only: [:show, :delete]

    #
    # Catalogue
    #
    resources "/products", ProductController, except: [:new, :edit] do
      resources "/prices", PriceController, only: [:index, :create]
    end
    resources "/prices", PriceController, only: [:show, :update, :delete]

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
    resources "/unlocks", UnlockController, only: [:index, :create, :show, :delete]

    #
    # MARK: Balance
    #
    resources "/cards", CardController, only: [:index, :create, :update, :delete]
    resources "/payments", PaymentController do
      resources "/refunds", RefundController, only: [:create]
    end

    get "/balance_settings", BalanceSettingsController, :show
    patch "/balance_settings", BalanceSettingsController, :update

    #
    # MARK: Fulfillment
    #
    resources "/fulfillment_packages", FulfillmentPackageController, only: [:index, :create, :show, :delete] do
      resources "/items", RefundController, only: [:create]
    end
    resources "/fulfillment_items", FulfillmentItemController, only: [:update, :delete]
    resources "/return_packages", ReturnPackageController, only: [:index, :delete]
    resources "/return_items", ReturnItemController, only: [:create, :delete]

    ####
    # Data Trading
    ####
    resources "/data_imports", DataImportController, only: [:index, :create, :show, :delete]

    #
    # Notification
    #
    resources "/notification_triggers", NotificationTriggerController, only: [:create, :show, :update, :index, :delete]
    resources "/emails", EmailController, only: [:index, :show]
    resources "/email_templates", EmailTemplateController, only: [:create, :show, :update, :index, :delete]
    resources "/sms", SmsController, only: [:index, :show]
    resources "/sms_templates", SmsTemplateController, only: [:create, :show, :update, :index, :delete]
  end
end
