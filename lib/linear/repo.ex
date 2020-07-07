defmodule Linear.Repo do
  use Ecto.Repo,
    otp_app: :linear,
    adapter: Ecto.Adapters.Postgres
end
