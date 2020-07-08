defmodule LinearWeb.SignupController do
  use LinearWeb, :controller

  alias Linear.Accounts
  alias Linear.Accounts.Account

  def index(conn, _params) do
    conn
    |> assign(:changeset, Accounts.change_account(%Account{}))
    |> render("index.html")
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

  def handle_account(conn, account = %Account{}) do
    conn
    |> put_session(:account_id, account.id)
    |> redirect(to: Routes.create_issue_path(conn, :index))
  end
end
