defmodule LinearWeb.GithubWebhookController do
  use LinearWeb, :controller

  def handle(conn, params) do
    Linear.Synchronize.handle_incoming(:github, params)
    json(conn, %{"success" => true})
  end
end
