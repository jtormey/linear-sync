defmodule LinearWeb.ErrorViewTest do
  use LinearWeb.ConnCase, async: true

  test "renders 404.html" do
    assert render_to_string(LinearWeb.ErrorHTML, "404.html", []) == "Not Found"
  end

  test "renders 500.html" do
    assert render_to_string(LinearWeb.ErrorHTML, "500.html", []) == "Internal Server Error"
  end

  # Test helpers

  defp render_to_string(module, template, assigns) do
    module.render(template, assigns)
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end
end
