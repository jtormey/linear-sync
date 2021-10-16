defmodule LinearWeb.GithubWebhookController do
  use LinearWeb, :controller

  alias Linear.Accounts
  alias Linear.Accounts.Account

  def handle(conn, %{"action" => "deleted", "installation" => %{"id" => installation_id}}) do
    query = [
      github_installation_id: to_string(installation_id)
    ]

    with %Account{} = account <- Accounts.get_account_by(query) do
      Accounts.delete_account_github_link(account)
    end

    json(conn, %{"success" => true})
  end

  def handle(conn, params) do
    Linear.Synchronize.handle_incoming(:github, params)
    json(conn, %{"success" => true})
  end
end
