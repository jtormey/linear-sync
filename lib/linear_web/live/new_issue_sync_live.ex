defmodule LinearWeb.NewIssueSyncLive do
  use LinearWeb, :live_view

  require Logger

  alias Linear.Repo
  alias Linear.Accounts
  alias Linear.Data
  alias Linear.Data.IssueSync
  alias Linear.IssueSyncService
  alias Linear.LinearAPI

  @impl true
  def mount(_params, %{"account_id" => account_id}, socket) do
    account = Accounts.get_account!(account_id)
    session = LinearAPI.Session.new(account.api_key)
    client = Tentacat.Client.new(%{access_token: account.github_token})

    {:ok, %{"data" => %{"viewer" => viewer, "teams" => %{"nodes" => teams}}}} = LinearAPI.viewer_teams(session)
    {200, repos, _response} = Tentacat.Repositories.list_mine(client)

    socket = socket
    |> assign(:page_title, "New Issue Sync")
    |> assign(:account, account)
    |> assign(:session, session)
    |> assign(:client, client)
    |> assign(:viewer, viewer)
    |> assign(:repos, Enum.map(repos, &repo_to_option/1))
    |> assign(:teams, Enum.map(teams, &decode_kv/1))
    |> assign(:labels, [])
    |> assign(:states, [])
    |> assign(:members, [])
    |> assign(:changeset, IssueSync.assoc_changeset(%IssueSync{}, account, %{}))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"issue_sync" => attrs}, socket) do
    socket = socket
    |> load_team(attrs["team_id"])
    |> assign(:changeset, build_changeset(socket, attrs) |> Map.put(:action, :insert))

    {:noreply, socket}
  end

  @impl true
  def handle_event("self_assign", _params, socket) do
    %{viewer: viewer, changeset: changeset} = socket.assigns

    changeset = Ecto.Changeset.put_change(changeset, :assignee_id, viewer["id"])

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("delete_existing", _params, socket) do
    %{account: account, changeset: changeset} = socket.assigns

    repo_id = Ecto.Changeset.fetch_change!(changeset, :repo_id)
    team_id = Ecto.Changeset.fetch_change!(changeset, :team_id)

    with {:ok, %{enabled: true} = issue_sync} <- {:ok, Data.get_issue_sync_by!(repo_id: repo_id, team_id: team_id)},
         {:error, reason} <- IssueSyncService.disable_issue_sync(issue_sync) do
      Logger.error("Failed to delete existing issue sync: #{inspect reason}")
    else
      {:ok, issue_sync} ->
        Data.delete_issue_sync(issue_sync)
    end

    changeset =
      IssueSync.assoc_changeset(%IssueSync{}, account, changeset.changes)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("submit", %{"issue_sync" => attrs}, socket) do
    case Repo.insert(build_changeset(socket, attrs)) do
      {:ok, _issue_sync} ->
        {:noreply, push_redirect(socket, to: Routes.dashboard_path(socket, :index))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def load_team(socket, "") do
    socket
    |> assign(:team_id, nil)
    |> assign(:labels, [])
    |> assign(:states, [])
    |> assign(:members, [])
  end

  def load_team(socket = %{assigns: %{team_id: team_id}}, team_id), do: socket

  def load_team(socket, team_id) do
    {:ok, %{"data" => %{"team" => result}}} = LinearAPI.new_issue_sync_data(socket.assigns.session, team_id)

    socket
    |> assign(:team_id, team_id)
    |> assign(:labels, Enum.map(result["labels"]["nodes"], &decode_kv/1))
    |> assign(:states, Enum.map(result["states"]["nodes"], &decode_kv/1))
    |> assign(:members, Enum.map(result["members"]["nodes"], &decode_kv/1))
  end

  def decode_kv(%{"id" => id, "name" => name}), do: [value: id, key: name]

  def repo_to_option(%{"id" => id, "name" => name, "owner" => owner}) do
    [value: id, key: "#{owner["login"]}/#{name}", owner: owner["login"], name: name]
  end

  def build_changeset(socket, attrs) do
    attrs =
      attrs
      |> put_source_name(socket)
      |> put_dest_name(socket)

    IssueSync.assoc_changeset(%IssueSync{}, socket.assigns.account, attrs)
  end

  def put_source_name(attrs, socket) do
    case attrs do
      %{"team_id" => team_id} ->
        team = Enum.find(socket.assigns.teams, &(&1[:value] == team_id))
        Map.put(attrs, "source_name", team[:key])

      _otherwise ->
        attrs
    end
  end

  def put_dest_name(attrs, socket) do
    case attrs do
      %{"repo_id" => repo_id} ->
        repo = Enum.find(socket.assigns.repos, &(to_string(&1[:value]) == repo_id))
        attrs
        |> Map.put("repo_id", repo[:value])
        |> Map.put("repo_owner", repo[:owner])
        |> Map.put("repo_name", repo[:name])
        |> Map.put("dest_name", repo[:key])

      _otherwise ->
        attrs
    end
  end

  def team_repo_constraint_error?(changeset) do
    case changeset.errors[:repo_id] do
      {_error, details} ->
        details[:validation] == :unsafe_unique

      _otherwise ->
        false
    end
  end
end
