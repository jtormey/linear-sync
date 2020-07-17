defmodule LinearWeb.DashboardLive do
  use LinearWeb, :live_view

  alias Linear.Accounts
  alias Linear.Data
  alias Linear.IssueSyncService

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

  @impl true
  def handle_event("enable", %{"issue_sync_id" => id}, socket) do
    %{account: account} = socket.assigns

    case IssueSyncService.enable_issue_sync(account, Data.get_issue_sync!(id)) do
      :ok ->
        {:noreply, assign(socket, :issue_syncs, Data.list_issue_syncs(account))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to enabled issue sync (#{inspect reason})")}
    end
  end

  @impl true
  def handle_event("disable", %{"issue_sync_id" => id}, socket) do
    %{account: account} = socket.assigns

    case IssueSyncService.disable_issue_sync(account, Data.get_issue_sync!(id)) do
      :ok ->
        {:noreply, assign(socket, :issue_syncs, Data.list_issue_syncs(account))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to enabled issue sync (#{inspect reason})")}
    end
  end
end
