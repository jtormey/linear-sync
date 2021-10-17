defmodule Linear.Actions.CreateLinearIssue do
  alias Linear.LinearAPI
  alias Linear.LinearAPI.LinearData, as: Ln
  alias Linear.LinearQuery
  alias Linear.Actions
  alias Linear.Actions.Helpers
  alias Linear.Synchronize.ContentWriter
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
        linear_issue = Ln.Issue.new(linear_issue_data)

        context =
          context
          |> Map.update!(
            :shared_issue,
            &Helpers.update_shared_issue!(&1, linear_issue)
          )
          |> Map.put(:linear_issue, linear_issue)

        {:cont, {context, next_actions(context)}}

      :error ->
        {:error, :create_linear_issue}
    end
  end

  defp next_actions(%{issue_sync: issue_sync} = context) do
    sync_github_issue_titles_actions =
      if issue_sync.sync_github_issue_titles do
        Actions.UpdateGithubIssue.new(%{
          title: ContentWriter.github_issue_title_from_linear(context.github_issue.title, context.linear_issue)
        })
      end

    close_on_open_actions =
      if issue_sync.close_on_open do
        [
          Actions.CreateGithubComment.new(%{
            body: ContentWriter.github_issue_moved_comment_body(context.linear_issue)
          }),
          Actions.UpdateGithubIssue.new(%{
            state: :closed
          })
        ]
      end

    Helpers.combine_actions([
      sync_github_issue_titles_actions,
      close_on_open_actions
    ])
  end
end
