defmodule LinearWeb.DashboardLive do
  use LinearWeb, :live_view

  alias Linear.Accounts
  alias Linear.LinearAPI

  @impl true
  def mount(_params, %{"account_id" => account_id}, socket) do
    account = Accounts.get_account!(account_id)

    session = LinearAPI.Session.new()
    {:ok, %{"data" => viewer}} = LinearAPI.viewer(session)
    # {:ok, %{"data" => %{"teams" => %{"nodes" => teams}}}} = LinearAPI.teams(session)
    # NEXT: Public link form

    IO.inspect viewer

    {:ok, assign(socket, :account, account)}
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: Routes.session_path(socket, :index))}
  end
end
