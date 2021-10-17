defmodule Linear.Actions.Helpers do
  alias Linear.Repo
  alias Linear.GithubAPI
  alias Linear.Data.IssueSync

  def client_repo_key(%IssueSync{} = issue_sync) do
    issue_sync = Repo.preload(issue_sync, :account)
    {GithubAPI.client(issue_sync.account), GithubAPI.to_repo_key!(issue_sync)}
  end

  # TODO: Replace with dispatch module
  def github_api() do
    Application.get_env(:linear, :github_api, GithubAPI)
  end
end
