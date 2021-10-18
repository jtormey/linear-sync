defmodule Linear.Synchronize.SyncEngine do
  require Logger

  alias Linear.Repo
  alias Linear.Actions
  alias Linear.Data
  alias Linear.Data.IssueSync
  alias Linear.Data.SharedIssue
  alias Linear.Data.SharedIssueLock
  alias Linear.Synchronize.Event

  @doc """
  """
  def handle_event(%Event{} = event) do
    event
    |> list_issue_syncs()
    |> Enum.map(&handle_issue_sync_event(&1, event))
  end

  @doc """
  """
  def handle_issue_sync_event(%IssueSync{} = issue_sync, %Event{} = event) do
    event = %Event{event | issue_sync_id: issue_sync.id}

    with {:error, :not_found} <- get_shared_issue(event),
         {:error, :invalid_constraint} <- create_shared_issue(event) do
      :noop
    else
      {:ok, shared_issue} ->
        context =
          Map.merge(event.data, %{
            issue_sync: issue_sync,
            shared_issue: shared_issue
          })

        Repo.transaction(fn ->
          {:ok, lock} = SharedIssueLock.acquire(shared_issue, max_attempts: 10)

          result =
            event
            |> Actions.for_event(context)
            |> Actions.Helpers.combine_actions()
            |> recurse_actions(context, &process_action/2)

          with {:ok, _context} <- result do
            {:ok, _lock} = SharedIssueLock.release(lock)
          end
        end)
    end
  end

  defp recurse_actions([], context, _process_fun), do: {:ok, context}

  defp recurse_actions([action | actions], context, process_fun) do
    case process_fun.(action, context) do
      {:ok, context} ->
        recurse_actions(actions, context, process_fun)

      {:cont, {context, []}} ->
        recurse_actions(actions, context, process_fun)

      {:cont, {context, child_actions}} ->
        child_actions = List.wrap(child_actions)
        recurse_actions(Enum.concat(child_actions, actions), context, process_fun)

      {:error, reason} = error ->
        Logger.error("[SyncEngine.recurse_actions/3] Exiting with reason: #{inspect(reason)}")
        error
    end
  end

  defp process_action(%action_type{} = action, context) do
    Logger.info("[SyncEngine.process_action/2] Processing action: #{inspect(action_type)}")

    should_process? =
      (not action_type.requires?(:linear) or context.shared_issue.linear_issue_id != nil) and
      (not action_type.requires?(:github) or context.shared_issue.github_issue_id != nil)

    if should_process? do
      action_type.process(action, context)
    else
      {:error, {:missing_requirement, action_type}}
    end
  end

  @doc """
  """
  def list_issue_syncs(%Event{source: :github} = event) do
    Data.list_issue_syncs_by_repo_id(event.data.github_repo.id)
  end

  def list_issue_syncs(%Event{source: :linear} = event) do
    cond do
      team_id = event.data.linear_issue.team_id ->
        Data.list_issue_syncs_by_team_id(team_id)

      linear_issue_id = event.data.linear_issue.id ->
        Data.list_issue_syncs_by_linear_issue_id(linear_issue_id)
    end
  end

  @doc """
  """
  def get_shared_issue(%Event{source: :github} = event) do
    query = [
      github_issue_id: event.data.github_issue.id,
      issue_sync_id: event.issue_sync_id
    ]
    Repo.get_by(SharedIssue, query) |> wrap_shared_issue_result()
  end

  def get_shared_issue(%Event{source: :linear} = event) do
    query = [
      linear_issue_id: event.data.linear_issue.id,
      issue_sync_id: event.issue_sync_id
    ]
    Repo.get_by(SharedIssue, query) |> wrap_shared_issue_result()
  end

  defp wrap_shared_issue_result(nil), do: {:error, :not_found}
  defp wrap_shared_issue_result(shared_issue), do: {:ok, shared_issue}

  @doc """
  """
  def create_shared_issue(%Event{} = event) do
    %SharedIssue{}
    |> SharedIssue.event_changeset(event)
    |> Repo.insert()
    |> Actions.Helpers.handle_constraint_error()
  end
end
