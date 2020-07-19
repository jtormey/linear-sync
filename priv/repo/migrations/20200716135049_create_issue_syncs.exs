defmodule Linear.Repo.Migrations.CreateIssueSyncs do
  use Ecto.Migration

  def change do
    create table(:issue_syncs) do
      add :external_id, :string, null: false
      add :source_name, :string, null: false
      add :dest_name, :string, null: false
      add :enabled, :boolean, default: false, null: false
      add :repo_id, :integer, null: false
      add :repo_owner, :string, null: false
      add :repo_name, :string, null: false
      add :team_id, :binary_id, null: false
      add :state_id, :binary_id
      add :label_id, :binary_id
      add :project_id, :binary_id
      add :self_assign, :boolean, default: false, null: false
      add :linear_webhook_id, :binary_id
      add :github_webhook_id, :integer
      add :account_id, references(:accounts, on_delete: :nothing, type: :binary_id), null: false

      timestamps()
    end

    create index(:issue_syncs, [:account_id])
    create index(:issue_syncs, [:repo_id])
    create unique_index(:issue_syncs, [:external_id])
    create unique_index(:issue_syncs, [:team_id, :repo_id])
  end
end
