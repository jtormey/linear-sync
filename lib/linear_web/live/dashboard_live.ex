defmodule LinearWeb.DashboardLive do
  use LinearWeb, :live_view

  alias Linear.Accounts

  def mount(_params, %{"account_id" => account_id}, socket) do
    account = Accounts.get_account!(account_id)
    {:ok, assign(socket, :account, account)}
  end

  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: Routes.signup_path(socket, :index))}
  end
end
