defmodule Linear.Repo.Migrations.AlterIssueSyncsAddInternalWebhooks do
  use Ecto.Migration

  def change do
    alter table(:issue_syncs) do
      add :linear_internal_webhook_id, references(:linear_webhooks, on_delete: :nilify_all)
      add :github_internal_webhook_id, references(:github_webhooks, on_delete: :nilify_all)
    end

    create index(:issue_syncs, [:linear_internal_webhook_id])
    create index(:issue_syncs, [:github_internal_webhook_id])
  end
end
