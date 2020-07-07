defmodule LinearWeb.CreateIssueLive do
  use LinearWeb, :live_view

  alias Linear.LinearAPI

  @impl true
  def mount(_params, _session, socket) do
    session = LinearAPI.Session.new()
    {:ok, %{"data" => %{"teams" => %{"nodes" => teams}}}} = LinearAPI.teams(session)
    {:ok, assign(socket, session: session, teams: teams)}
  end
end
