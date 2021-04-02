defmodule LinearWeb.EditIssueSyncLive do
  use LinearWeb, :live_view

  import LinearWeb.NewIssueSyncLive, only: [load_team: 2]

  alias Linear.Repo
  alias Linear.Accounts
  alias Linear.Data
  alias Linear.Data.IssueSync
  alias Linear.LinearAPI

  @impl true
  def mount(%{"id" => id}, %{"account_id" => account_id}, socket) do
    issue_sync = Data.get_issue_sync!(id)
    account = Accounts.get_account!(account_id)

    if issue_sync.account_id != account.id do
      {:ok, push_redirect(socket, to: Routes.dashboard_path(socket, :index))}
    else
      session = LinearAPI.Session.new(account.api_key)

      {:ok, %{"data" => %{"viewer" => viewer}}} = LinearAPI.viewer(session)

      socket = socket
      |> assign(:page_title, "Edit Issue Sync")
      |> assign(:account, account)
      |> assign(:session, session)
      |> assign(:issue_sync, issue_sync)
      |> assign(:viewer, viewer)
      |> assign(:changeset, IssueSync.changeset(issue_sync, %{}))
      |> load_team(issue_sync.team_id)

      {:ok, socket}
    end
  end

  @impl true
  def handle_event("validate", %{"issue_sync" => attrs}, socket) do
    changeset = IssueSync.changeset(socket.assigns.issue_sync, attrs)
    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("submit", _params, socket) do
    case Repo.update(socket.assigns.changeset) do
      {:ok, _issue_sync} ->
        {:noreply, push_redirect(socket, to: Routes.dashboard_path(socket, :index))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
