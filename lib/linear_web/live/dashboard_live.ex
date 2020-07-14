defmodule LinearWeb.DashboardLive do
  use LinearWeb, :live_view

  alias Linear.Accounts
  alias Linear.Integrations

  @impl true
  def mount(_params, %{"account_id" => account_id}, socket) do
    account = Accounts.get_account!(account_id)
    public_entries = Integrations.list_public_entries(account)

    socket = socket
    |> assign(:account, account)
    |> assign(:public_entries, public_entries)
    |> assign(:shown_issues, MapSet.new())
    |> assign(:issue_groups, Integrations.group_ln_issues(account))

    {:ok, socket}
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: Routes.session_path(socket, :index))}
  end

  @impl true
  def handle_event("show_created", %{"public_entry_id" => public_entry_id}, socket) do
    shown_issues = socket.assigns.shown_issues
    shown_issues = if MapSet.member?(shown_issues, public_entry_id) do
      MapSet.delete(shown_issues, public_entry_id)
    else
      MapSet.put(shown_issues, public_entry_id)
    end
    {:noreply, assign(socket, :shown_issues, shown_issues)}
  end
end
