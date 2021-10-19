defmodule Linear.Actions do
  require Logger

  alias __MODULE__
  alias Linear.Synchronize.Event
  alias Linear.Synchronize.ContentWriter

  @doc """
  """
  def for_event(%Event{source: :github, action: :opened_issue} = event, context) do
    handle_existing_linear_issue =
      if context.issue_sync.sync_github_issue_titles do
        fn issue_key ->
          [
            Actions.FetchLinearIssue.new(%{
              issue_key: issue_key,
              replace_shared_issue: true
            }),
            Actions.CreateLinearComment.new(%{
              body: ContentWriter.linear_comment_issue_linked_body(event.data.github_issue)
            })
          ]
        end
      else
        fn _issue_key -> [] end
      end

    case ContentWriter.parse_linear_issue_keys(event.data.github_issue.title) do
      [] ->
        create_linear_issue? =
          context.shared_issue.linear_issue_id == nil and
            not ContentWriter.via_linear_sync?(event.data.github_issue.body)

        if create_linear_issue? do
          Actions.CreateLinearIssue.new(%{
            title: ContentWriter.linear_issue_title(event.data.github_repo, event.data.github_issue),
            body: ContentWriter.linear_issue_body(event.data.github_repo, event.data.github_issue)
          })
        end

      [issue_key] ->
        handle_existing_linear_issue.(issue_key)

      [issue_key | _rest]->
        Logger.warn("Multiple linear issue keys per github issue not supported, using the first found")
        handle_existing_linear_issue.(issue_key)
    end
  end

  def for_event(%Event{source: :github, action: :reopened_issue}, context) do
    Actions.UpdateLinearIssue.new(%{
      state_id: context.issue_sync.open_state_id
    })
  end

  def for_event(%Event{source: :github, action: :closed_issue}, context) do
    if not context.issue_sync.close_on_open do
      Actions.UpdateLinearIssue.new(%{
        state_id: context.issue_sync.close_state_id
      })
    end
  end

  def for_event(%Event{source: :github, action: :created_comment} = event, _context) do
    create_linear_comment? =
      not ContentWriter.via_linear_sync?(event.data.github_comment.body)

    if create_linear_comment? do
      Actions.CreateLinearComment.new(%{
        body: ContentWriter.linear_comment_body(event.data.github_comment)
      })
    end
  end

  def for_event(%Event{source: :github, action: :labeled_issue} = event, _context) do
    [
      Actions.FetchLinearLabels.new(),
      Actions.FetchLinearIssue.new(),
      Actions.UpdateLinearIssue.new(%{
        add_labels: [event.data.github_label]
      })
    ]
  end

  def for_event(%Event{source: :github, action: :unlabeled_issue} = event, _context) do
    [
      Actions.FetchLinearLabels.new(),
      Actions.FetchLinearIssue.new(),
      Actions.UpdateLinearIssue.new(%{
        remove_labels: [event.data.github_label]
      })
    ]
  end

  def for_event(%Event{source: :linear, action: :created_issue} = event, context) do
    create_github_issue? =
      context.shared_issue.github_issue_id == nil and
        not ContentWriter.via_linear_sync?(event.data.linear_issue.description)

    if context.issue_sync.sync_linear_to_github and create_github_issue? do
      github_issue_title =
        if context.issue_sync.sync_github_issue_titles do
          ContentWriter.github_issue_title_from_linear(event.data.linear_issue)
        else
          event.data.linear_issue.title
        end

      [
        Actions.BlockLinearPrivateIssue.new(),
        Actions.CreateGithubIssue.new(%{
          title: github_issue_title,
          body: ContentWriter.github_issue_body(event.data.linear_issue)
        })
      ]
    end
  end

  def for_event(%Event{source: :linear, action: :updated_issue} = event, context) do
    if context.issue_sync.sync_linear_to_github do
      [
        with %{open_state_id: state_id} <- context.issue_sync,
             %{added_state_id: ^state_id} <- event.data.linear_state_diff do
          Actions.UpdateGithubIssue.new(%{
            state: :opened
          })
        else
          _otherwise -> nil
        end,
        with %{close_state_id: state_id} <- context.issue_sync,
             %{added_state_id: ^state_id} <- event.data.linear_state_diff do
          Actions.UpdateGithubIssue.new(%{
            state: :closed
          })
        else
          _otherwise -> nil
        end,
        if event.data.linear_labels_diff do
          [
            Actions.FetchLinearLabels.new(),
            Actions.FetchGithubLabels.new(),
            Actions.AddGithubLabels.new(%{
              label_ids: event.data.linear_labels_diff.added_label_ids
            }),
            Actions.RemoveGithubLabels.new(%{
              label_ids: event.data.linear_labels_diff.removed_label_ids
            })
          ]
        end
      ]
    end
  end

  def for_event(%Event{source: :linear, action: :created_comment} = event, context) do
    create_github_comment? =
      context.issue_sync.sync_linear_to_github and
        not ContentWriter.via_linear_sync?(event.data.linear_comment.body)

    if create_github_comment? do
      [
        Actions.BlockLinearPrivateIssue.new(),
        Actions.FetchLinearIssue.new(),
        Actions.CreateGithubComment.new(%{
          create_body: fn context ->
            ContentWriter.github_issue_comment_body(
              context.linear_issue,
              event.data.linear_comment.body
            )
          end
        })
      ]
    end
  end
end
