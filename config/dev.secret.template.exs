import Config

ngrok_host = "000000000000.ngrok.io"

config :linear, Linear.Repo,
  username: "postgres",
  password: "postgres",
  database: "linear_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :linear, LinearWeb.Endpoint, url: [scheme: "https", host: ngrok_host, port: 443]

config :oauth2, debug: true

config :linear, Linear.Auth.Github,
  client_id: "GITHUB_CLIENT_ID",
  client_secret: "GITHUB_CLIENT_SECRET",
  redirect_uri: "https://#{ngrok_host}/auth/github/callback",
  scope: "repo"
