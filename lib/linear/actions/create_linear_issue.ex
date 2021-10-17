defmodule Linear.Actions.CreateLinearIssue do
  alias Linear.Repo
  alias Linear.LinearAPI
  alias Linear.LinearQuery
  alias Linear.Actions
  alias Linear.Util

  @enforce_keys [:title, :body]
  defstruct [:title, :body]

  def new(fields), do: struct(__MODULE__, fields)

  def process(%__MODULE__{} = action, %{issue_sync: issue_sync} = context) do
    session = LinearAPI.Session.new(issue_sync.account)

    args = [
      teamId: issue_sync.team_id,
      title: action.title,
      description: action.body
    ]

    args =
      args
      |> Util.Control.put_non_nil(:stateId, issue_sync.open_state_id)
      |> Util.Control.put_non_nil(:labelIds, issue_sync.label_id, &List.wrap/1)
      |> Util.Control.put_non_nil(:assigneeId, issue_sync.assignee_id)

    case LinearQuery.create_issue(session, args) do
      {:ok, linear_issue_data} ->
        context =
          Map.update!(
            context,
            :shared_issue,
            &update_shared_issue!(&1, linear_issue_data)
          )

        {:cont, {context, next_actions(context)}}

      :error ->
        {:error, :create_linear_issue}
    end
  end

  defp update_shared_issue!(shared_issue, linear_issue) do
    shared_issue
    |> Ecto.Changeset.change(
      linear_issue_id: linear_issue["id"],
      linear_issue_number: linear_issue["number"]
    )
    |> Repo.update!()
  end

  defp next_actions(%{issue_sync: issue_sync}) do
    # format_gh_issue_title(gh_issue.title, format_issue_key(attrs))

    args =
      %{}
      |> Util.Control.put_if(:title, "Updated title", issue_sync.sync_github_issue_titles)
      |> Util.Control.put_if(:state, :closed, issue_sync.close_on_open)

    if args == %{}, do: [], else: Actions.UpdateGithubIssue.new(args)
  end
end
