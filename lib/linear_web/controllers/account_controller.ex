defmodule LinearWeb.AccountController do
  use LinearWeb, :controller

  require Logger

  alias Linear.Accounts

  def delete(conn, _params) do
    account_id = get_session(conn, :account_id)
    account = Accounts.get_account!(account_id)

    case Accounts.delete_account(account) do
      {:ok, _account} ->
        conn
        |> delete_session(:account_id)
        |> put_flash(:info, "Successfully deleted your LinearSync account.")
        |> redirect(to: Routes.session_path(conn, :index))

      {:error, reason} ->
        Logger.error("Failed to delete account #{inspect(account.id)} #{inspect(reason)}")

        conn
        |> put_flash(
          :info,
          "Failed to delete your LinearSync account, please email justin@93software.com for assistance."
        )
        |> redirect(to: Routes.dashboard_path(conn, :index))
    end
  end
end
