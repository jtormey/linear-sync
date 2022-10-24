defmodule Linear.Repo.Migrations.CreatePublicEntries do
  use Ecto.Migration

  def change do
    create table(:public_entries) do
      add :name, :string, null: false
      add :external_id, :string, null: false
      add :enabled, :boolean, null: false
      add :team_id, :binary_id, null: false
      add :state_id, :binary_id
      add :label_id, :binary_id
      add :project_id, :binary_id
      add :assign_self, :boolean, default: false, null: false

      add :account_id, references(:accounts, on_delete: :delete_all, type: :binary_id),
        null: false

      timestamps()
    end

    create index(:public_entries, [:account_id])
  end
end
