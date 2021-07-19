defmodule Linear.Repo.Migrations.AlterIssueSyncsAddSyncOptions do
  use Ecto.Migration

  def change do
    alter table(:issue_syncs) do
      add :sync_linear_to_github, :boolean, default: false, null: false
      add :sync_github_issue_titles, :boolean, default: false, null: false
    end
  end
end
