defmodule Linear.Factory do
  use ExMachina.Ecto, repo: Linear.Repo

  def account_factory() do
    %Linear.Accounts.Account{}
  end

  def issue_sync_factory() do
    %Linear.Data.IssueSync{
      dest_name: "test-owner/test-repo",
      source_name: "test-linear-team",
      external_id: Ecto.UUID.generate(),

      # Github
      repo_id: 200001,
      repo_owner: "test-owner",
      repo_name: "test-repo",

      # Linear
      team_id: Ecto.UUID.generate(),
      enabled: true,
      label_id: nil,
      assignee_id: nil,
      open_state_id: nil,
      close_state_id: nil,

      # Settings
      close_on_open: false,
      sync_linear_to_github: false,
      sync_github_issue_titles: false,

      # Associations
      account: build(:account)
    }
  end

  def shared_issue_factory() do
    %Linear.Data.SharedIssue{
      # Linear
      linear_issue_id: Ecto.UUID.generate(),
      linear_issue_number: 93,

      # Github
      github_issue_id: 100001,
      github_issue_number: 101,

      # Associations
      issue_sync: build(:issue_sync)
    }
  end
end
