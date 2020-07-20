defmodule LinearWeb.LinearWebhookController do
  use LinearWeb, :controller

  def handle(conn, params) do
    Linear.Synchronize.handle_incoming(:linear, params)
    json(conn, %{"success" => true})
  end
end
