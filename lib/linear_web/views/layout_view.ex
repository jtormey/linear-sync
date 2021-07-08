defmodule LinearWeb.LayoutView do
  use LinearWeb, :view

  def render_flashes(conn_or_flash) do
    ~E"""
    <div class="alert-container">
      <%= render_flash(conn_or_flash, :info) %>
      <%= render_flash(conn_or_flash, :error) %>
    </div>
    """
  end

  def render_flash(conn_or_flash, type) do
    if content = get_flash_content(conn_or_flash, type) do
      ~E"""
      <div class="alert alert-<%= type %>" role="alert"<%= render_flash_controls(conn_or_flash, type) %>>
        <p><%= content %></p>
      </div>
      """
    end
  end

  defp get_flash_content(%Plug.Conn{} = conn, type), do: get_flash(conn, type)
  defp get_flash_content(flash, type), do: live_flash(flash, type)

  defp render_flash_controls(%Plug.Conn{}, _type), do: ~E()

  defp render_flash_controls(_flash, type),
    do: ~E( phx-click="lv:clear-flash" phx-value-key="<%= type %>")
end
