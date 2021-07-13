defmodule Linear.LinearQuery do
  require Logger

  alias Linear.LinearAPI
  alias Linear.LinearAPI.Session
  alias Linear.Data.LnIssue

  @doc """
  Gets an issue in Linear by ID, i.e. "ABC-12"
  """
  def get_issue_by_id(%Session{} = session, ln_issue_id) do
    result = LinearAPI.issue(session, ln_issue_id)

    case result do
      {:ok, %{"data" => %{"issue" => issue}}} ->
        {:ok, issue}

      error ->
        Logger.error("Error getting Linear issue by ID, #{inspect error}")
        :error
    end
  end

  @doc """
  Creates an issue in Linear
  """
  def create_issue(%Session{} = session, args) do
    result = LinearAPI.create_issue(session, args)

    case result do
      {:ok, %{"data" => %{"issueCreate" => %{"success" => true, "issue" => attrs}}}} ->
        {:ok, attrs}

      error ->
        Logger.error("Error syncing Github issue to Linear, #{inspect error}")
        :error
    end
  end

  @doc """
  Updates an issue in Linear.

  Possible args: [:title, :description, :stateId, :labelIds, :assigneeId]
  """
  def update_issue(%Session{} = session, %LnIssue{} = ln_issue, args) do
    args = Keyword.merge(args, issueId: ln_issue.id)

    result = LinearAPI.update_issue(session, args)

    case result do
      {:ok, %{"data" => %{"issueUpdate" => %{"success" => true}}}} ->
        :ok

      error ->
        Logger.error("Error updating Linear issue, #{inspect error}")
        :error
    end
  end

  @doc """
  Creates a comment on an issue in Linear.

  Possible args: [:body]
  """
  def create_issue_comment(%Session{} = session, %LnIssue{} = ln_issue, args) do
    args = Keyword.merge(args, issueId: ln_issue.id)

    result = LinearAPI.create_comment(session, args)

    case result do
      {:ok, %{"data" => %{"commentCreate" => %{"success" => true, "comment" => attrs}}}} ->
        {:ok, attrs}

      error ->
        Logger.error("Error creating Linear issue comment, #{inspect error}")
        :error
    end
  end

  @doc """
  Lists all labels currently applied to an issue in Linear.
  """
  def list_issue_labels(%Session{} = session, %LnIssue{} = ln_issue) do
    result = LinearAPI.issue(session, ln_issue.id)

    case result do
      {:ok, %{"data" => %{"issue" => issue}}} ->
        {:ok, issue["labels"]["nodes"]}

      error ->
        Logger.error("Error listing Linear issue label ids, #{inspect error}")
        :error
    end
  end

  @doc """
  Lists all labels in Linear.
  """
  def list_labels(%Session{} = session) do
    result = LinearAPI.list_issue_labels(session)

    case result do
      {:ok, %{"data" => %{"issueLabels" => %{"nodes" => issue_labels}}}} ->
        {:ok, issue_labels}

      error ->
        Logger.error("Error listing Linear labels, #{inspect error}")
        :error
    end
  end
end
