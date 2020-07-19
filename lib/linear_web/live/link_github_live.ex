defmodule LinearWeb.LinkGithubLive do
  use LinearWeb, :live_view

  alias Linear.Accounts
  alias Linear.Accounts.Account

  @impl true
  def mount(_params, %{"account_id" => account_id}, socket) do
    case Accounts.get_account!(account_id) do
      %Account{github_token: nil} = account ->
        Accounts.subscribe(account)
        {:ok, assign(socket, page_title: "Link GitHub", linking?: false)}

      %Account{} ->
        {:ok, redirect(socket, to: Routes.dashboard_path(socket, :index))}
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: Routes.session_path(socket, :index))}
  end

  @impl true
  def handle_event("link_start", _params, socket) do
    {:noreply, assign(socket, :linking?, true)}
  end

  @impl true
  def handle_info({:github_link, account = %Account{}}, socket) do
    if account.github_token != nil do
      {:noreply, redirect(socket, to: Routes.dashboard_path(socket, :index))}
    else
      {:noreply, socket}
    end
  end
end
