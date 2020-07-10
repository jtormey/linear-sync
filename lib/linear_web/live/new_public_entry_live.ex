defmodule LinearWeb.NewPublicEntryLive do
  use LinearWeb, :live_view

  alias Linear.Repo
  alias Linear.Accounts
  alias Linear.Integrations
  alias Linear.Integrations.PublicEntry
  alias Linear.LinearAPI

  @impl true
  def mount(_params, %{"account_id" => account_id}, socket) do
    account = Accounts.get_account!(account_id)
    session = LinearAPI.Session.new(account.api_key)

    {:ok, %{"data" => %{"viewer" => viewer, "teams" => %{"nodes" => teams}}}} = LinearAPI.viewer_teams(session)

    socket = socket
    |> assign(:account, account)
    |> assign(:session, session)
    |> assign(:viewer, viewer)
    |> assign(:teams, Enum.map(teams, &decode_kv/1))
    |> assign(:labels, [])
    |> assign(:states, [])
    |> assign(:projects, [])
    |> assign(:changeset, Integrations.change_public_entry(%PublicEntry{}, account))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"public_entry" => attrs}, socket) do
    socket = socket
    |> load_team(attrs["team_id"])
    |> assign(:changeset, PublicEntry.changeset(%PublicEntry{}, socket.assigns.account, attrs))

    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", _params, socket) do
    case Repo.insert(socket.assigns.changeset) do
      {:ok, _public_entry} ->
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
    {:ok, %{"data" => %{"team" => result}}} = LinearAPI.new_public_entry_data(socket.assigns.session, team_id)

    socket
    |> assign(:team_id, team_id)
    |> assign(:labels, Enum.map(result["labels"]["nodes"], &decode_kv/1))
    |> assign(:states, Enum.map(result["states"]["nodes"], &decode_kv/1))
    |> assign(:projects, Enum.map(result["projects"]["nodes"], &decode_kv/1))
  end

  def decode_kv(%{"id" => id, "name" => name}), do: [value: id, key: name]
end
