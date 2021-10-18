defmodule Linear.Repo.Migrations.CreateSharedIssuesSharedComments do
  use Ecto.Migration

  def change do
    create table(:shared_issues) do
      # Linear data
      add :linear_issue_id, :binary_id
      add :linear_issue_number, :integer

      # Github data
      add :github_issue_id, :integer
      add :github_issue_number, :integer

      # Associations
      add :issue_sync_id, references(:issue_syncs, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:shared_issues, [:issue_sync_id])
    create unique_index(:shared_issues, [:linear_issue_id])
    create unique_index(:shared_issues, [:github_issue_id])

    create table(:shared_issue_locks) do
      add :shared_issue_id, references(:shared_issues, on_delete: :delete_all), null: false
      add :expires_at, :utc_datetime, null: false

      timestamps(updated_at: false)
    end

    create unique_index(:shared_issue_locks, [:shared_issue_id])
  end
end
