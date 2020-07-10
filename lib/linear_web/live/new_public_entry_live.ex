defmodule LinearWeb.NewPublicEntryLive do
  use LinearWeb, :live_view

  alias Linear.Accounts
  alias Linear.Integrations
  alias Linear.Integrations.PublicEntry
  alias Linear.LinearAPI

  @impl true
  def mount(_params, %{"account_id" => account_id}, socket) do
    account = Accounts.get_account!(account_id)
    session = LinearAPI.Session.new()

    {:ok, %{"data" => %{"teams" => %{"nodes" => teams}}}} = LinearAPI.teams(session)

    socket = socket
    |> assign(:account, account)
    |> assign(:session, session)
    |> assign(:open_menu, nil)
    |> assign(:teams, Enum.map(teams, fn %{"id" => id, "name" => name} -> [value: id, key: name] end))
    |> assign(:labels, [])
    |> assign(:states, [])
    |> assign(:projects, [])
    |> assign(:changeset, Integrations.change_public_entry(%PublicEntry{}))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"public_entry" => %{"team" => team_id}}, socket) do
    socket = load_data(socket, team_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("open_menu", params = %{"menu_id" => menu_id}, socket) do
    IO.inspect params
    {:noreply, assign(socket, :open_menu, menu_id)}
  end

  def load_data(socket, ""), do: socket

  def load_data(socket = %{assigns: %{team_id: team_id}}, team_id), do: socket

  def load_data(socket, team_id) do
    {:ok, %{"data" => %{"team" => result}}} = LinearAPI.new_public_entry_data(socket.assigns.session, team_id)

    socket
    |> assign(:team_id, team_id)
    |> assign(:labels, Enum.map(result["labels"]["nodes"], &decode_kv/1))
    |> assign(:states, Enum.map(result["states"]["nodes"], &decode_kv/1))
    |> assign(:projects, Enum.map(result["projects"]["nodes"], &decode_kv/1))
  end

  def decode_kv(%{"id" => id, "name" => name}), do: [value: id, key: name]
end
