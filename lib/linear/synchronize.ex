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

    repo_id = "#{repo["owner"]["login"]}/#{repo["name"]}"

    Enum.each Data.list_enabled_issue_syncs(repo_id), fn issue_sync ->
      session = LinearAPI.Session.new(issue_sync.account)

      title =
        """
        "#{title}" (#{repo_id} ##{number})
        """

      description =
        """
        #{body}

        ___

        [#{repo_id} ##{number}](#{issue["html_url"]}) by [@#{user["login"]}](#{user["html_url"]}) on GitHub
        """

      result = LinearAPI.create_issue session,
        teamId: issue_sync.team_id,
        title: title,
        description: description

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

  def handle_incoming(scope, params) do
    IO.inspect "Unhandled in scope #{scope}, #{inspect params}"
  end
end
