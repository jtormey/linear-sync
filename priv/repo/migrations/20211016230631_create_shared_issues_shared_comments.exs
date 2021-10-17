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

    create table(:shared_comments) do
      # Linear data
      add :linear_comment_id, :binary_id

      # Github data
      add :github_comment_id, :integer

      # Associations
      add :shared_issue_id, references(:shared_issues, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:shared_comments, [:shared_issue_id])
    create unique_index(:shared_comments, [:linear_comment_id])
    create unique_index(:shared_comments, [:github_comment_id])
  end
end
