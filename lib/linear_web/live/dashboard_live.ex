defmodule LinearWeb.DashboardLive do
  use LinearWeb, :live_view

  alias Linear.Accounts
  alias Linear.Integrations

  @impl true
  def mount(_params, %{"account_id" => account_id}, socket) do
    account = Accounts.get_account!(account_id)
    public_entries = Integrations.list_public_entries(account)
    {:ok, assign(socket, account: account, public_entries: public_entries)}
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: Routes.session_path(socket, :index))}
  end
end
