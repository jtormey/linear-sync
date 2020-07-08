defmodule LinearWeb.SignupLive do
  use LinearWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("signup", %{"signup" => %{"api_key" => _api_key}}, socket) do
    {:noreply, socket}
  end
end
