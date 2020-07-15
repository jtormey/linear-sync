defmodule LinearWeb.AuthGithubController do
  use LinearWeb, :controller

  alias Linear.Auth

  def auth(conn, _params) do
    redirect(conn, external: Auth.Github.authorize_url!())
  end

  def callback(conn, params = %{"code" => _code}) do
    IO.inspect params
    redirect(conn, to: Routes.auth_github_path(conn, :done))
  end

  def done(conn, _params) do
    render(conn, "done.html")
  end
end
