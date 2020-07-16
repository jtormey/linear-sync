defmodule LinearWeb.DashboardLive do
  use LinearWeb, :live_view

  alias Linear.Accounts
  alias Linear.Data

  @impl true
  def mount(_params, %{"account_id" => account_id}, socket) do
    account = Accounts.get_account!(account_id)
    issue_syncs = Data.list_issue_syncs(account)

    socket = socket
    |> assign(:account, account)
    |> assign(:issue_syncs, issue_syncs)

    {:ok, socket}
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: Routes.session_path(socket, :index))}
  end
end
