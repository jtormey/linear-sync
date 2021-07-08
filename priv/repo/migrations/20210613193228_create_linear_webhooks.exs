defmodule Linear.Repo.Migrations.CreateLinearWebhooks do
  use Ecto.Migration

  def change do
    create table(:linear_webhooks) do
      add :team_id, :string, null: false
      add :webhook_id, :string

      timestamps()
    end

    create unique_index(:linear_webhooks, [:team_id])
    create unique_index(:linear_webhooks, [:webhook_id])
  end
end
