defmodule LinearWeb.CreateIssueLive do
  use LinearWeb, :live_view
  use Ecto.Schema

  alias Linear.LinearAPI
  alias Linear.Accounts
  alias Linear.Integrations

  @impl true
  def mount(%{"param" => param}, _params, socket) do
    public_entry = Integrations.get_public_entry_from_param!(param)
    {:ok, assign(socket, public_entry: public_entry)}
  end

  @impl true
  def handle_event("submit", %{"issue" => attrs}, socket) do
    %{public_entry: public_entry} = socket.assigns

    account = Accounts.get_account!(public_entry.account_id)
    session = LinearAPI.Session.new(account)

    {:ok, %{"data" => %{"issueCreate" => %{"issue" => issue}}}} =
      LinearAPI.create_issue(session, public_entry.team_id, attrs["title"], attrs["description"])

    IO.inspect(issue)
    # %{"description" => "", "id" => "99f763d2-83d0-4053-9083-f63791f3e541", "title" => "Public create"}

    {:noreply, socket}
  end
end
