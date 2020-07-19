defmodule Linear.Repo.Migrations.CreateLnComments do
  use Ecto.Migration

  def change do
    alter table(:ln_issues) do
      modify :description, :text, from: :string
      add :github_issue_id, :integer, null: false
    end

    create index(:ln_issues, [:github_issue_id])

    create table(:ln_comments) do
      add :body, :text, null: false
      add :github_comment_id, :integer, null: false
      add :ln_issue_id, references(:ln_issues, on_delete: :delete_all, type: :binary_id), null: false

      timestamps()
    end

    create index(:ln_comments, [:ln_issue_id])
    create index(:ln_comments, [:github_comment_id])
  end
end
