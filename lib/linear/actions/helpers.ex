defmodule Linear.Actions.Helpers do
  alias Linear.Repo
  alias Linear.GithubAPI
  alias Linear.Data.IssueSync
  alias Linear.LinearAPI.LinearData, as: Ln

  def client_repo_key(%IssueSync{} = issue_sync) do
    issue_sync = Repo.preload(issue_sync, :account)
    {GithubAPI.client(issue_sync.account), GithubAPI.to_repo_key!(issue_sync)}
  end

  # TODO: Replace with dispatch module
  def github_api() do
    Application.get_env(:linear, :github_api, GithubAPI)
  end

  def combine_actions(actions) do
    Enum.flat_map(actions, fn
      nil ->
        []

      actions ->
        List.wrap(actions)
    end)
  end

  def update_shared_issue!(shared_issue, %Ln.Issue{} = linear_issue) do
    shared_issue
    |> Ecto.Changeset.change(
      linear_issue_id: linear_issue.id,
      linear_issue_number: linear_issue.number
    )
    |> Repo.update!()
  end
end
