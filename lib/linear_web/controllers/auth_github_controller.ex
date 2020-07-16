defmodule LinearWeb.AuthGithubController do
  use LinearWeb, :controller

  alias Linear.Auth
  alias Linear.Accounts
  alias Linear.Accounts.Account

  def auth(conn, _params) do
    case session_account(conn) do
      %Account{} = account ->
        state = Ecto.UUID.generate()
        {:ok, _account} = Accounts.update_account_github_link(account, %{github_link_state: state})
        redirect(conn, external: Auth.Github.authorize_url!(state))

      _otherwise ->
        conn
        |> put_flash(:error, "Failed to retrieve account session")
        |> redirect(to: Routes.auth_github_path(conn, :done))
    end
  end

  def callback(conn, %{"code" => code, "state" => state}) do
    case session_account(conn) do
      %Account{github_link_state: ^state} = account ->
        %{token: %{access_token: access_token}} = Auth.Github.get_token!(code: code)
        {:ok, _account} = Accounts.update_account_github_link(account, %{github_token: access_token, github_link_state: nil})
        redirect(conn, to: Routes.auth_github_path(conn, :done))

      _otherwise ->
        conn
        |> put_flash(:error, "Received unknown state code")
        |> redirect(to: Routes.auth_github_path(conn, :done))
    end
  end

  def done(conn, _params) do
    render(conn, "done.html")
  end

  def session_account(conn) do
    account_id = get_session(conn, :account_id)
    account_id && Accounts.get_account!(account_id)
  end
end
