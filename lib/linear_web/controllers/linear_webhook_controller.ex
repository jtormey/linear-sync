defmodule LinearWeb.LinearWebhookController do
  use LinearWeb, :controller

  def handle(conn, params) do
    IO.inspect params
    json(conn, %{"success" => true})
  end
end
