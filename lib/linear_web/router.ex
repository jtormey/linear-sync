defmodule LinearWeb.Router do
  use LinearWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LinearWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LinearWeb do
    pipe_through :browser

    # Legacy OAuth Apps
    get "/auth/github", AuthGithubController, :auth
    get "/auth/github/callback", AuthGithubController, :callback
    get "/auth/github/done", AuthGithubController, :done
    post "/auth/github/relink", AuthGithubController, :relink

    # GitHub Apps
    get "/auth/github/app/pre-auth", AuthGithubAppController, :pre_auth
    get "/auth/github/app", AuthGithubAppController, :auth
    get "/auth/github/app/callback", AuthGithubAppController, :callback

    resources "/", SessionController, only: [:index]
    resources "/", SessionController, only: [:create, :delete], singleton: true
    resources "/account", AccountController, only: [:delete], singleton: true

    live "/link/github", LinkGithubLive, :index

    live "/account", DashboardLive, :index
    live "/account/issue-sync/new", NewIssueSyncLive, :index
    live "/account/issue-sync/:id/edit", EditIssueSyncLive, :index
    live "/account/webhooks", WebhooksLive, :index
  end

  scope "/", LinearWeb do
    pipe_through :api

    post "/webhook/linear", LinearWebhookController, :handle
    post "/webhook/github", GithubWebhookController, :handle
  end
end
