defmodule Linear.Synchronize do
  @moduledoc """

  From Github
    - Open issue -> Create in Linear
    - Comment on issue -> Comment in Linear
    - Close issue -> Mark as Done in Linear

  From Linear
    - Mark issue as Done -> Close in Github
    (?)
    - Comment contains +sync-close -> Close in Github
    - Comment contains +sync-comment -> Comment in Github

  """

  require Logger

  alias Linear.Accounts
  alias Linear.Data
  alias Linear.LinearAPI
  alias Linear.LinearQuery
  alias Linear.GithubAPI
  alias Linear.GithubAPI.GithubData, as: Gh
  alias Linear.Synchronize.ContentWriter

  @doc """
  Given a scope, handles an incoming webhook message.
  """
  def handle_incoming(:github, %{"action" => "opened", "repository" => gh_repo} = params) do
    if gh_issue = params["issue"] || params["pull_request"] do
      handle_github_issue_opened(Gh.Repo.new(gh_repo), Gh.Issue.new(gh_issue))
    end
  end

  def handle_incoming(:github, %{"action" => "closed"} = params) do
    if gh_issue = params["issue"] || params["pull_request"] do
      handle_github_issue_closed(Gh.Issue.new(gh_issue))
    end
  end

  def handle_incoming(:github, %{"action" => "created", "comment" => gh_comment, "issue" => gh_issue}) do
    handle_github_comment_created(Gh.Issue.new(gh_issue), Gh.Comment.new(gh_comment))
  end

  def handle_incoming(:github, %{"action" => "labeled", "label" => gh_label} = params) do
    if gh_issue = params["issue"] || params["pull_request"] do
      handle_github_issue_labeled(Gh.Issue.new(gh_issue), Gh.Label.new(gh_label))
    end
  end

  def handle_incoming(:github, %{"action" => "unlabeled", "label" => gh_label} = params) do
    if gh_issue = params["issue"] || params["pull_request"] do
      handle_github_issue_unlabeled(Gh.Issue.new(gh_issue), Gh.Label.new(gh_label))
    end
  end

  def handle_incoming(:linear, %{"action" => "update"} = params) do
    IO.inspect(params)
  end

  def handle_incoming(scope, params) do
    Logger.warn "Unhandled action in scope #{scope} => #{params["action"] || "?"}"
  end

  @doc """
  Handles an issue or pull request opened event.
  """
  def handle_github_issue_opened(%Gh.Repo{} = gh_repo, %Gh.Issue{} = gh_issue) do
    case parse_linear_issue_ids(gh_issue.title) do
      [] ->
        Enum.each Data.list_issue_syncs_by_repo_id(gh_repo.id), fn issue_sync ->
          create_ln_issue_from_gh_issue(issue_sync, gh_repo, gh_issue)
        end

      _issue_ids ->
        :noop
    end
  end

  @doc """
  Handles an issue or pull request closed event.
  """
  def handle_github_issue_closed(%Gh.Issue{} = gh_issue) do
    Enum.each Data.list_ln_issues_by_github_issue_id(gh_issue.id), fn ln_issue ->
      if ln_issue.issue_sync.close_state_id != nil and not ln_issue.issue_sync.close_on_open do
        session = LinearAPI.Session.new(ln_issue.issue_sync.account)
        LinearQuery.update_issue(session, ln_issue, stateId: ln_issue.issue_sync.close_state_id)
      end
    end
  end

  @doc """
  Handles a comment created event.
  """
  def handle_github_comment_created(%Gh.Issue{} = gh_issue, %Gh.Comment{} = gh_comment) do
    Enum.each Data.list_ln_issues_by_github_issue_id(gh_issue.id), fn ln_issue ->
      session = LinearAPI.Session.new(ln_issue.issue_sync.account)

      args = [
        body: ContentWriter.linear_comment_body(gh_comment)
      ]

      with {:ok, attrs} <- LinearQuery.create_issue_comment(session, ln_issue, args) do
        attrs = Map.put(attrs, "github_comment_id", gh_comment.id)
        {:ok, _ln_comment} = Data.create_ln_comment(ln_issue, attrs)
      end
    end
  end

  @doc """
  Handles an issue or pull request labeled event.
  """
  def handle_github_issue_labeled(%Gh.Issue{} = gh_issue, %Gh.Label{} = gh_label) do
    Enum.each Data.list_ln_issues_by_github_issue_id(gh_issue.id), fn ln_issue ->
      if ln_label = get_corresponding_ln_issue_label(ln_issue.issue_sync, gh_label) do
        update_ln_issue_labels(ln_issue, & &1 ++ [ln_label["id"]])
      end
    end
  end

  @doc """
  Handles an issue or pull request unlabeled event.
  """
  def handle_github_issue_unlabeled(%Gh.Issue{} = gh_issue, %Gh.Label{} = gh_label) do
    Enum.each Data.list_ln_issues_by_github_issue_id(gh_issue.id), fn ln_issue ->
      if ln_label = get_corresponding_ln_issue_label(ln_issue.issue_sync, gh_label) do
        update_ln_issue_labels(ln_issue, & &1 -- [ln_label["id"]])
      end
    end
  end

  defp update_ln_issue_labels(ln_issue, map_fun) when is_function(map_fun, 1) do
    session = LinearAPI.Session.new(ln_issue.issue_sync.account)

    with {:ok, labels} = LinearQuery.list_issue_labels(session, ln_issue) do
      label_ids = Enum.map(labels, & &1["id"])
      LinearQuery.update_issue(session, ln_issue, labelIds: map_fun.(label_ids))
    end
  end

  defp get_corresponding_ln_issue_label(issue_sync, %Gh.Label{} = gh_label) do
    session = LinearAPI.Session.new(issue_sync.account)

    with {:ok, ln_labels} <- LinearQuery.list_labels(session) do
      Enum.find ln_labels, fn ln_label ->
        match? = String.downcase(ln_label["name"]) == gh_label.name
        match? && ln_label
      end
    else
      :error ->
        nil
    end
  end

  @doc """
  Creates a Linear issue given an issue_sync and Github data.
  """
  def create_ln_issue_from_gh_issue(issue_sync, %Gh.Repo{} = gh_repo, %Gh.Issue{} = gh_issue) do
    session = LinearAPI.Session.new(issue_sync.account)

    args = [
      teamId: issue_sync.team_id,
      title: ContentWriter.linear_issue_title(gh_repo, gh_issue),
      description: ContentWriter.linear_issue_body(gh_repo, gh_issue)
    ]

    args = if issue_sync.open_state_id != nil do
      Keyword.put(args, :stateId, issue_sync.open_state_id)
    else
      args
    end

    args = if issue_sync.label_id != nil do
      Keyword.put(args, :labelIds, [issue_sync.label_id])
    else
      args
    end

    args = if issue_sync.assignee_id != nil do
      Keyword.put(args, :assigneeId, issue_sync.assignee_id)
    else
      args
    end

    with {:ok, attrs} <- LinearQuery.create_issue(session, args) do
      attrs = Map.put(attrs, "github_issue_id", gh_issue.id)
      {:ok, ln_issue} = Data.create_ln_issue(issue_sync, attrs)

      client = GithubAPI.client(Accounts.get_account!(issue_sync.account_id))
      repo_key = GithubAPI.to_repo_key!(issue_sync)

      GithubAPI.update_issue(client, repo_key, gh_issue.number, %{
        "title" => format_issue_key(attrs) <> " " <> gh_issue.title
      })

      if issue_sync.close_on_open do
        comment = ContentWriter.github_issue_moved_comment_body(ln_issue)

        GithubAPI.create_issue_comment(client, repo_key, gh_issue.number, comment)
        GithubAPI.close_issue(client, repo_key, gh_issue.number)
      end
    end
  end

  defp format_issue_key(%{"number" => issue_number, "team" => %{"key" => team_key}}) do
    "[#{team_key}-#{issue_number}]"
  end

  @doc """
  Parses Linear issue identifiers from a binary.

  ## Examples

    iex> parse_linear_issue_ids("[LN-93] My Github issue")
    ["[LN-93]"]

  """
  def parse_linear_issue_ids(title) when is_binary(title) do
    Regex.scan(~r/\[[A-Z0-9]+-\d+\]/, title) |> List.flatten()
  end
end
