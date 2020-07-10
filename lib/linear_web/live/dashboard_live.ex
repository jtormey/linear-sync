defmodule LinearWeb.DashboardLive do
  use LinearWeb, :live_view

  alias Linear.Accounts

  @impl true
  def mount(_params, %{"account_id" => account_id}, socket) do
    account = Accounts.get_account!(account_id)
    {:ok, assign(socket, :account, account)}
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: Routes.session_path(socket, :index))}
  end
end
