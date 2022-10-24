defmodule LinearWeb.AuthGithubController do
  use LinearWeb, :controller

  alias Linear.Auth
  alias Linear.Accounts
  alias Linear.Accounts.Account

  def auth(conn, _params) do
    case session_account(conn) do
      %Account{} = account ->
        state = Ecto.UUID.generate()

        {:ok, _account} =
          Accounts.update_account_github_link(account, %{github_link_state: state})

        redirect(conn, external: Auth.Github.authorize_url!(state))

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

  def callback(conn, %{"code" => code, "state" => state}) do
    case session_account(conn) do
      %Account{github_link_state: ^state} = account ->
        %{token: %{access_token: access_token}} = Auth.Github.get_token!(code: code)

        {:ok, _account} =
          Accounts.update_account_github_link(account, %{
            github_token: access_token,
            github_link_state: nil
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

  def done(conn, _params) do
    render(conn, "done.html")
  end

  def relink(conn, _params) do
    %Account{} = account = session_account(conn)

    case account do
      %Account{github_installation_id: val} when is_binary(val) ->
        Auth.GithubApp.delete_app_authorization!(val)

      %Account{github_token: val} when is_binary(val) ->
        Auth.Github.delete_app_authorization!(val)

      _otherwise ->
        :noop
    end

    case Accounts.delete_account_github_link(account) do
      {:ok, %Account{} = _account} ->
        conn
        |> redirect(to: Routes.link_github_path(conn, :index))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to initiate GitHub re-linking.")
        |> redirect(to: Routes.link_github_path(conn, :index))
    end
  end

  def session_account(conn) do
    account_id = get_session(conn, :account_id)
    account_id && Accounts.get_account!(account_id)
  end
end
