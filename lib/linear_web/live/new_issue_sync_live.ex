defmodule LinearWeb.NewIssueSyncLive do
  use LinearWeb, :live_view

  alias Linear.Repo
  alias Linear.Accounts
  alias Linear.Data.IssueSync
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
    |> assign(:projects, [])
    |> assign(:changeset, IssueSync.assoc_changeset(%IssueSync{}, account, %{}))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"issue_sync" => attrs}, socket) do
    attrs = attrs
    |> put_source_name(socket)
    |> put_dest_name(socket)

    socket = socket
    |> load_team(attrs["team_id"])
    |> assign(:changeset, IssueSync.assoc_changeset(%IssueSync{}, socket.assigns.account, attrs))

    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", _params, socket) do
    case Repo.insert(socket.assigns.changeset) do
      {:ok, _issue_sync} ->
        {:noreply, redirect(socket, to: Routes.dashboard_path(socket, :index))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def load_team(socket, "") do
    socket
    |> assign(:team_id, nil)
    |> assign(:labels, [])
    |> assign(:states, [])
    |> assign(:projects, [])
  end

  def load_team(socket = %{assigns: %{team_id: team_id}}, team_id), do: socket

  def load_team(socket, team_id) do
    {:ok, %{"data" => %{"team" => result}}} = LinearAPI.new_issue_sync_data(socket.assigns.session, team_id)

    socket
    |> assign(:team_id, team_id)
    |> assign(:labels, Enum.map(result["labels"]["nodes"], &decode_kv/1))
    |> assign(:states, Enum.map(result["states"]["nodes"], &decode_kv/1))
    |> assign(:projects, Enum.map(result["projects"]["nodes"], &decode_kv/1))
  end

  def decode_kv(%{"id" => id, "name" => name}), do: [value: id, key: name]

  def repo_to_option(%{"id" => id, "name" => name, "owner" => owner}) do
    [value: id, key: "#{owner["login"]}/#{name}", owner: owner["login"], name: name]
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
end
