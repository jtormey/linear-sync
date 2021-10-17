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
  def attrs(%Event{} = event) do
    %{
      github_issue_id: get_in(event.data, [:github_issue, :id]),
      github_issue_number: get_in(event.data, [:github_issue, :number]),
      github_comment_id: get_in(event.data, [:github_comment, :id]),
      linear_issue_id: get_in(event.data, [:linear_issue, :id]),
      linear_issue_number: get_in(event.data, [:linear_issue, :number]),
      linear_comment_id: get_in(event.data, [:linear_comment, :id]),
      issue_sync_id: event.issue_sync_id
    }
  end
end
