defmodule Linear.Repo.Migrations.CreatePublicEntries do
  use Ecto.Migration

  def change do
    create table(:public_entries) do
      add :name, :string
      add :team_id, :binary_id
      add :state_id, :binary_id
      add :label_id, :binary_id
      add :project_id, :binary_id
      add :assign_self, :boolean, default: false, null: false
      add :account_id, references(:accounts, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:public_entries, [:account_id])
  end
end
