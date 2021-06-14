defmodule LinearWeb.SessionController do
  use LinearWeb, :controller

  alias Linear.Accounts
  alias Linear.Accounts.Account

  @page_title "Login"

  def index(conn, _params) do
    case get_session(conn, :account_id) do
      nil ->
        conn
        |> assign(:page_title, @page_title)
        |> assign(:changeset, Accounts.change_account(%Account{}))
        |> render("index.html")

      _account_id ->
        redirect(conn, to: Routes.dashboard_path(conn, :index))
    end
  end

  def create(conn, %{"account" => %{"api_key" => api_key}}) do
    case Accounts.find_or_create_account(api_key) do
      {:ok, %Account{} = account} ->
        handle_account(conn, account)

      {:replaced, %Account{} = account} ->
        conn
        |> put_flash(:info, "We found an existing Linear organization, welcome back!")
        |> handle_account(account)

      {:error, :invalid_api_key} ->
        conn
        |> put_flash(:error, "Please enter a valid Linear API key.")
        |> redirect(to: Routes.dashboard_path(conn, :index))
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
