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
  alias Linear.GithubAPI
  alias Linear.GithubAPI.GithubData

  @doc """
  Given a scope, handles an incoming webhook message.
  """
  def handle_incoming(:github, %{"action" => "opened", "issue" => gh_issue, "repository" => gh_repo}) do
    gh_repo = GithubData.Repo.new(gh_repo)
    gh_issue = GithubData.Issue.new(gh_issue)

    case parse_linear_issue_ids(gh_issue.title) do
      [] ->
        Enum.each Data.list_issue_syncs_by_repo_id(gh_repo.id), fn issue_sync ->
          create_ln_issue_from_gh_issue(issue_sync, gh_issue)
        end

      _issue_ids ->
        :noop
    end
  end

  def handle_incoming(:github, %{"action" => "created", "comment" => gh_comment, "issue" => gh_issue}) do
    gh_issue = GithubData.Issue.new(gh_issue)
    gh_comment = GithubData.Comment.new(gh_comment)

    Enum.each Data.list_ln_issues_by_github_issue_id(gh_issue.id), fn ln_issue ->
      session = LinearAPI.Session.new(ln_issue.issue_sync.account)

      body =
        """
        #{gh_comment.body}
        ___
        [Comment](#{gh_comment.html_url}) by [@#{gh_comment.user.login}](#{gh_comment.user.html_url}) on GitHub
        """

      result = LinearAPI.create_comment session,
        issueId: ln_issue.id,
        body: body

      case result do
        {:ok, %{"data" => %{"commentCreate" => %{"success" => true, "comment" => attrs}}}} ->
          {:ok, ln_comment} = Data.create_ln_comment(ln_issue, Map.put(attrs, "github_comment_id", gh_comment.id))
          {:ok, ln_comment}

        error ->
          Logger.error("Error syncing Github comment to Linear, #{inspect error}")
      end
    end
  end

  def handle_incoming(:github, %{"action" => "closed", "issue" => gh_issue}) do
    gh_issue = GithubData.Issue.new(gh_issue)

    Enum.each Data.list_ln_issues_by_github_issue_id(gh_issue.id), fn ln_issue ->
      if ln_issue.issue_sync.close_state_id != nil and not ln_issue.issue_sync.close_on_open do
        session = LinearAPI.Session.new(ln_issue.issue_sync.account)

        result = LinearAPI.update_issue session,
          issueId: ln_issue.id,
          stateId: ln_issue.issue_sync.close_state_id

        case result do
          {:ok, %{"data" => %{"issueUpdate" => %{"success" => true}}}} ->
            :ok

          error ->
            Logger.error("Error syncing status to Linear issue, #{inspect error}")
        end
      end
    end
  end

  def handle_incoming(scope, params) do
    Logger.warn "Unhandled action in scope #{scope} => #{params["action"] || "?"}"
  end

  def parse_linear_issue_ids(title) when is_binary(title) do
    Regex.scan(~r/\[[A-Z0-9]+-\d+\]/, title) |> List.flatten()
  end

  def create_ln_issue_from_gh_issue(issue_sync, %GithubData.Issue{} = gh_issue) do
    session = LinearAPI.Session.new(issue_sync.account)

    issue_name = "#{issue_sync.repo_owner}/#{issue_sync.repo_name} ##{gh_issue.number}"

    title =
      """
      "#{gh_issue.title}" (#{issue_name})
      """

    description =
      """
      #{gh_issue.body}

      #{unless gh_issue.body == "", do: "___"}

      [#{issue_name}](#{gh_issue.html_url}) by [@#{gh_issue.user.login}](#{gh_issue.user.html_url}) on GitHub
      """

    opts = [
      teamId: issue_sync.team_id,
      title: title,
      description: description
    ]

    opts = if issue_sync.open_state_id != nil do
      Keyword.put(opts, :stateId, issue_sync.open_state_id)
    else
      opts
    end

    opts = if issue_sync.label_id != nil do
      Keyword.put(opts, :labelIds, [issue_sync.label_id])
    else
      opts
    end

    opts = if issue_sync.assignee_id != nil do
      Keyword.put(opts, :assigneeId, issue_sync.assignee_id)
    else
      opts
    end

    result = LinearAPI.create_issue session, opts

    case result do
      {:ok, %{"data" => %{"issueCreate" => %{"success" => true, "issue" => attrs}}}} ->
        {:ok, ln_issue} = Data.create_ln_issue(issue_sync, Map.put(attrs, "github_issue_id", gh_issue.id))

        if issue_sync.close_on_open do
          comment =
            """
            Automatically moved to [Linear (##{ln_issue.number})](#{ln_issue.url})
            """

          client = GithubAPI.client(Accounts.get_account!(issue_sync.account_id))
          repo_key = GithubAPI.to_repo_key!(issue_sync)

          GithubAPI.create_issue_comment(client, repo_key, gh_issue.number, comment)
          GithubAPI.close_issue(client, repo_key, gh_issue.number)
        end

        {:ok, ln_issue}

      error ->
        Logger.error("Error syncing Github issue to Linear, #{inspect error}")
        :error
    end
  end
end
