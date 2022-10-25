# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :linear,
  ecto_repos: [Linear.Repo]

config :linear, :generators, binary_id: true

config :linear, Linear.Repo,
  migration_primary_key: [name: :id, type: :binary_id],
  migration_timestamps: [type: :utc_datetime]

# Configures the endpoint
config :linear, LinearWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "xCQwaiDYqj3vZmL55d8+oVDk21+6kbx9mHKgXb5wl370QEZ1/ukPmwGBeX5BnyPR",
  render_errors: [view: LinearWeb.ErrorHTML, accepts: ~w(html json), layout: false],
  pubsub_server: Linear.PubSub,
  live_view: [signing_salt: "1jIiBu4B"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
