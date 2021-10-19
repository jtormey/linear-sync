defmodule Linear.Synchronize do
  @moduledoc false

  require Logger

  alias Linear.Actions
  alias Linear.Synchronize.SyncEngine
  alias Linear.Synchronize.Event
  alias Linear.GithubAPI.GithubData, as: Gh
  alias Linear.LinearAPI.LinearData, as: Ln

  @doc """
  Given a scope, handles an incoming webhook message.
  """
  def handle_incoming(:github, %{"action" => "opened", "repository" => gh_repo} = params) do
    %Event{
      source: :github,
      action: :opened_issue,
      data: %{
        github_repo: Gh.Repo.new(gh_repo),
        github_issue: Gh.Issue.new(params["issue"] || params["pull_request"])
      }
    }
    |> SyncEngine.handle_event()
  end

  def handle_incoming(:github, %{"action" => "reopened", "repository" => gh_repo} = params) do
    %Event{
      source: :github,
      action: :reopened_issue,
      data: %{
        github_repo: Gh.Repo.new(gh_repo),
        github_issue: Gh.Issue.new(params["issue"] || params["pull_request"])
      }
    }
    |> SyncEngine.handle_event()
  end

  def handle_incoming(:github, %{"action" => "closed", "repository" => gh_repo} = params) do
    %Event{
      source: :github,
      action: :closed_issue,
      data: %{
        github_repo: Gh.Repo.new(gh_repo),
        github_issue: Gh.Issue.new(params["issue"] || params["pull_request"])
      }
    }
    |> SyncEngine.handle_event()
  end

  def handle_incoming(:github, %{"action" => "created", "comment" => gh_comment, "issue" => gh_issue, "repository" => gh_repo}) do
    %Event{
      source: :github,
      action: :created_comment,
      data: %{
        github_repo: Gh.Repo.new(gh_repo),
        github_issue: Gh.Issue.new(gh_issue),
        github_comment: Gh.Comment.new(gh_comment)
      }
    }
    |> SyncEngine.handle_event()
  end

  def handle_incoming(:github, %{"action" => "labeled", "label" => gh_label, "repository" => gh_repo} = params) do
    %Event{
      source: :github,
      action: :labeled_issue,
      data: %{
        github_repo: Gh.Repo.new(gh_repo),
        github_issue: Gh.Issue.new(params["issue"] || params["pull_request"]),
        github_label: Gh.Label.new(gh_label)
      }
    }
    |> SyncEngine.handle_event()
  end

  def handle_incoming(:github, %{"action" => "unlabeled", "label" => gh_label, "repository" => gh_repo} = params) do
    %Event{
      source: :github,
      action: :unlabeled_issue,
      data: %{
        github_repo: Gh.Repo.new(gh_repo),
        github_issue: Gh.Issue.new(params["issue"] || params["pull_request"]),
        github_label: Gh.Label.new(gh_label)
      }
    }
    |> SyncEngine.handle_event()
  end

  def handle_incoming(:linear, %{"action" => "create", "type" => "Issue", "data" => ln_issue}) do
    %Event{
      source: :linear,
      action: :created_issue,
      data: %{
        linear_issue: Ln.Issue.new(ln_issue)
      }
    }
    |> SyncEngine.handle_event()
  end

  def handle_incoming(:linear, %{"action" => "update", "type" => "Issue", "data" => ln_issue} = params) do
    %Event{
      source: :linear,
      action: :updated_issue,
      data: %{
        linear_issue: Ln.Issue.new(ln_issue),
        linear_labels_diff: Actions.Helpers.Labels.get_updated_linear_labels(params)
      }
    }
    |> SyncEngine.handle_event()
  end

  def handle_incoming(:linear, %{"action" => "create", "type" => "Comment", "data" => %{"issue" => ln_issue} = ln_comment}) do
    %Event{
      source: :linear,
      action: :created_comment,
      data: %{
        linear_issue: Ln.Issue.new(ln_issue),
        linear_comment: Ln.Comment.new(ln_comment)
      }
    }
    |> SyncEngine.handle_event()
  end

  def handle_incoming(scope, params) do
    Logger.warn "Unhandled action in scope #{scope} => #{params["action"] || "?"}"
  end
end
