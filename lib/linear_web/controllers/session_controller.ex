defmodule LinearWeb.SessionController do
  use LinearWeb, :controller

  alias Linear.Accounts
  alias Linear.Accounts.Account

  def index(conn, _params) do
    case get_session(conn, :account_id) do
      nil ->
        conn
        |> assign(:changeset, Accounts.change_account(%Account{}))
        |> render("index.html")

      _account_id ->
        redirect(conn, to: Routes.dashboard_path(conn, :index))
    end
  end

  def create(conn, %{"account" => %{"api_key" => api_key} = account_attrs}) do
    case Accounts.get_account_by(api_key: api_key) do
      %Account{} = account ->
        handle_account(conn, account)

      nil ->
        case Accounts.create_account(account_attrs) do
          {:ok, %Account{} = account} ->
            handle_account(conn, account)

          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, "index.html", changeset: changeset)
        end
    end
  end

  def delete(conn, _params) do
    conn
    |> delete_session(:account_id)
    |> redirect(to: Routes.session_path(conn, :index))
  end

  def handle_account(conn, account = %Account{}) do
    conn
    |> put_session(:account_id, account.id)
    |> redirect(to: Routes.link_github_path(conn, :index))
  end
end
