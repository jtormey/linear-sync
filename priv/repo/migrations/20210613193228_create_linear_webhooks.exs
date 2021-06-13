defmodule Linear.Repo.Migrations.CreateLinearWebhooks do
  use Ecto.Migration

  def change do
    create table(:linear_webhooks) do
      add :team_id, :string, null: false
      add :webhook_id, :string
      add :account_id, references(:accounts, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:linear_webhooks, [:team_id])
    create unique_index(:linear_webhooks, [:webhook_id])
    create index(:linear_webhooks, [:account_id])
  end
end
