defmodule LinearWeb.WebhooksLive do
  use LinearWeb, :live_view

  alias Linear.Accounts
  alias Linear.Webhooks

  @impl true
  def mount(_params, %{"account_id" => account_id}, socket) do
    account = Accounts.get_account!(account_id)
    webhooks = Webhooks.list_webhooks(account)
    {:ok, assign(socket, :webhooks, webhooks)}
  end
end
