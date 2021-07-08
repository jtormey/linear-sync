defmodule Linear.Repo.Migrations.AlterLnIssuesAddGhIssueNumber do
  use Ecto.Migration

  def change do
    alter table(:ln_issues) do
      add :github_issue_number, :integer
    end
  end
end
