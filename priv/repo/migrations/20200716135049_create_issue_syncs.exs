defmodule Linear.Repo.Migrations.CreateIssueSyncs do
  use Ecto.Migration

  def change do
    create table(:issue_syncs) do
      add :external_id, :string, null: false
      add :source_name, :string, null: false
      add :dest_name, :string, null: false
      add :enabled, :boolean, default: false, null: false
      add :repo_id, :string, null: false
      add :team_id, :binary_id, null: false
      add :state_id, :binary_id
      add :label_id, :binary_id
      add :project_id, :binary_id
      add :self_assign, :boolean, default: false, null: false
      add :account_id, references(:accounts, on_delete: :nothing, type: :binary_id), null: false

      timestamps()
    end

    create unique_index(:issue_syncs, [:external_id])
    create index(:issue_syncs, [:account_id])
  end
end