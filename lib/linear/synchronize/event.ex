defmodule Linear.Synchronize.Event do
  alias __MODULE__

  @enforce_keys [
    :source,
    :action,
    :data
  ]

  defstruct [
    :source,
    :action,
    :issue_sync_id,
    data: %{}
  ]

  @doc """
  Returns the possible attrs for an event.
  """
  def attrs(%Event{data: data} = event) do
    %{
      github_issue_id: data[:github_issue] && data.github_issue.id,
      github_issue_number: data[:github_issue] && data.github_issue.number,
      github_comment_id: data[:github_comment] && data.github_comment.id,
      linear_issue_id: data[:linear_issue] && data.linear_issue.id,
      linear_issue_number: data[:linear_issue] && data.linear_issue.number,
      linear_comment_id: data[:linear_comment] && data.linear_comment.id,
      issue_sync_id: event.issue_sync_id
    }
  end
end
