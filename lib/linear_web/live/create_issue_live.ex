defmodule LinearWeb.CreateIssueLive do
  use LinearWeb, :live_view
  use Ecto.Schema

  alias Linear.LinearAPI
  alias Linear.Accounts
  alias Linear.Integrations

  @impl true
  def mount(%{"param" => param}, params, socket) do
    socket = socket
    |> assign(:public_entry, Integrations.get_public_entry_from_param!(param))
    |> assign(:signed_in?, params["account_id"] != nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("submit", %{"issue" => attrs}, socket) do
    %{public_entry: public_entry} = socket.assigns

    account = Accounts.get_account!(public_entry.account_id)
    session = LinearAPI.Session.new(account)

    {:ok, %{"data" => %{"issueCreate" => %{"issue" => issue_attrs}}}} =
      LinearAPI.create_issue(session, public_entry.team_id, attrs["title"], attrs["description"])

    {:ok, _ln_issue} = Integrations.create_ln_issue(public_entry, issue_attrs)

    socket = socket
    |> put_flash(:info, "Successfully created issue")
    |> redirect(to: Routes.create_issue_path(socket, :index, public_entry))

    {:noreply, socket}
  end
end
