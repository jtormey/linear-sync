defmodule LinearWeb.AuthGithubAppController do
  use LinearWeb, :controller

  alias Linear.Auth
  alias Linear.Accounts
  alias Linear.Accounts.Account
  alias Linear.GithubAPI

  def pre_auth(conn, _params) do
    conn
    |> assign(:auth_github_path, Routes.auth_github_app_path(conn, :auth))
    |> render("pre_auth.html")
  end

  def auth(conn, %{"info" => %{"gh_target" => gh_target}}) do
    with {:ok, target_id} <- GithubAPI.user_id_by_username(gh_target),
         %Account{} = account <- session_account(conn) do
      state = Ecto.UUID.generate()
      {:ok, _account} = Accounts.update_account_github_link(account, %{github_link_state: state})
      redirect(conn, external: Auth.GithubApp.authorize_url!(target_id))
    else
      {:error, :not_found} ->
        conn
        |> put_flash(:error, "User or organization not found")
        |> redirect(to: Routes.auth_github_app_path(conn, :pre_auth))

      _otherwise ->
        conn
        |> put_flash(:error, "Failed to retrieve account session")
        |> redirect(to: Routes.auth_github_path(conn, :done))
    end
  end

  def callback(conn, %{"error_description" => error_description}) do
    conn
    |> put_flash(:error, "Error installing GitHub App: #{inspect(error_description)}")
    |> redirect(to: Routes.auth_github_path(conn, :done))
  end

  def callback(conn, %{"code" => code, "installation_id" => installation_id, "setup_action" => _action}) do
    case session_account(conn) do
      %Account{} = account ->
        %{token: %{access_token: access_token}} = Auth.GithubApp.get_token!(code: code)

        {:ok, _account} =
          Accounts.update_account_github_link(account, %{
            github_token: access_token,
            github_link_state: nil,
            github_installation_id: installation_id
          })

        redirect(conn, to: Routes.auth_github_path(conn, :done))

      nil ->
        conn
        |> put_flash(:error, "Please sign-in before installing LinearSync on GitHub")
        |> redirect(to: Routes.session_path(conn, :index))

      _otherwise ->
        conn
        |> put_flash(:error, "Received unknown state code")
        |> redirect(to: Routes.auth_github_path(conn, :done))
    end
  end

  def session_account(conn) do
    account_id = get_session(conn, :account_id)
    account_id && Accounts.get_account!(account_id)
  end
end
