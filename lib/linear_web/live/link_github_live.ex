defmodule LinearWeb.LinkGithubLive do
  use LinearWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket = socket |> assign(:linking?, false)
    {:ok, socket}
  end

  @impl true
  def handle_event("link_start", _params, socket) do
    {:noreply, assign(socket, :linking?, true)}
  end
end
