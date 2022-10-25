import Config

config :linear, Linear.Repo,
  url: System.fetch_env!("DATABASE_URL"),
  socket_options: [:inet6],
  pool_size: 10

config :linear, LinearWeb.Endpoint,
  http: [port: String.to_integer(System.fetch_env!("PORT"))],
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
  server: true

config :linear, Linear.Auth.GithubApp,
  app_id: System.fetch_env!("GITHUB_APP_ID"),
  app_name: System.fetch_env!("GITHUB_APP_NAME"),
  client_id: System.fetch_env!("GITHUB_APP_CLIENT_ID"),
  client_secret: System.fetch_env!("GITHUB_APP_CLIENT_SECRET"),
  redirect_uri: System.fetch_env!("GITHUB_APP_REDIRECT_URI")
