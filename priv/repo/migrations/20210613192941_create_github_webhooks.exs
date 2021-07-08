defmodule Linear.Repo.Migrations.CreateGithubWebhooks do
  use Ecto.Migration

  def change do
    create table(:github_webhooks) do
      add :repo_id, :integer, null: false
      add :repo_owner, :string, null: false
      add :repo_name, :string, null: false
      add :webhook_id, :integer

      timestamps()
    end

    create unique_index(:github_webhooks, [:repo_id])
    create unique_index(:github_webhooks, [:repo_owner, :repo_name])
    create unique_index(:github_webhooks, [:webhook_id])
  end
end
