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

  alias Linear.Data
  alias Linear.LinearAPI

  def handle_incoming(:github, %{"action" => "opened", "issue" => issue, "repository" => repo}) do
    %{"id" => _id, "title" => title, "body" => body, "number" => number, "user" => user} = issue

    Enum.each Data.list_issue_syncs_by_repo_id(repo["id"]), fn issue_sync ->
      session = LinearAPI.Session.new(issue_sync.account)

      issue_name = "#{issue_sync.repo_owner}/#{issue_sync.repo_name} ##{number}"

      title =
        """
        "#{title}" (#{issue_name})
        """

      description =
        """
        #{body}

        #{unless body == "", do: "___"}

        [#{issue_name}](#{issue["html_url"]}) by [@#{user["login"]}](#{user["html_url"]}) on GitHub
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

      result = LinearAPI.create_issue session, opts

      case result do
        {:ok, %{"data" => %{"issueCreate" => %{"success" => true, "issue" => attrs}}}} ->
          {:ok, ln_issue} = Data.create_ln_issue(issue_sync, Map.put(attrs, "github_issue_id", issue["id"]))
          {:ok, ln_issue}

        error ->
          Logger.error("Error syncing Github issue to Linear, #{inspect error}")
          :error
      end
    end
  end

  def handle_incoming(:github, %{"action" => "created", "comment" => comment, "issue" => issue}) do
    %{"body" => body, "user" => user} = comment

    Enum.each Data.list_ln_issues_by_github_issue_id(issue["id"]), fn ln_issue ->
      session = LinearAPI.Session.new(ln_issue.issue_sync.account)

      body =
        """
        #{body}
        ___
        [Comment](#{comment["html_url"]}) by [@#{user["login"]}](#{user["html_url"]}) on GitHub
        """

      result = LinearAPI.create_comment session,
        issueId: ln_issue.id,
        body: body

      case result do
        {:ok, %{"data" => %{"commentCreate" => %{"success" => true, "comment" => attrs}}}} ->
          {:ok, ln_comment} = Data.create_ln_comment(ln_issue, Map.put(attrs, "github_comment_id", comment["id"]))
          {:ok, ln_comment}

        error ->
          Logger.error("Error syncing Github comment to Linear, #{inspect error}")
      end
    end
  end

  def handle_incoming(:github, %{"action" => "closed", "issue" => issue}) do
    Enum.each Data.list_ln_issues_by_github_issue_id(issue["id"]), fn ln_issue ->
      if ln_issue.issue_sync.close_state_id != nil do
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
    IO.inspect "Unhandled in scope #{scope}, #{inspect params}"
  end
end
