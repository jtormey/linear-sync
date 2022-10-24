defmodule LinearWeb.ErrorHTML do
  use LinearWeb, :html

  embed_templates "../templates/error/*"

  def render(template, assigns) do
    component = String.to_atom(String.trim_trailing(template, ".html"))

    if function_exported?(__MODULE__, component, 1) do
      apply(__MODULE__, component, [assigns])
    else
      template_not_found(template, assigns)
    end
  end

  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  # def render("500.html", _assigns) do
  #   "Internal Server Error"
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.html" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
