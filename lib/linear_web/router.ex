defmodule LinearWeb.Router do
  use LinearWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LinearWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LinearWeb do
    pipe_through :browser

    get "/auth/github", AuthGithubController, :auth
    get "/auth/github/callback", AuthGithubController, :callback
    get "/auth/github/done", AuthGithubController, :done

    resources "/", SessionController, only: [:index]
    resources "/", SessionController, only: [:create, :delete], singleton: true

    live "/link/github", LinkGithubLive, :index

    live "/account", DashboardLive, :index
    live "/account/public-entry/new", NewPublicEntryLive, :index
    live "/account/issue-sync/new", NewIssueSyncLive, :index
    live "/issue/:param", CreateIssueLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", LinearWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: LinearWeb.Telemetry
    end
  end
end
