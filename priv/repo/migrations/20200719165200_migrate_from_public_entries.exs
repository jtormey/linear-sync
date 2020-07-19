defmodule Linear.Repo.Migrations.MigrateFromPublicEntries do
  use Ecto.Migration

  def change do
    alter table(:ln_issues) do
      remove :public_entry_id, references(:public_entries, on_delete: :delete_all), null: false
      add :issue_sync_id, references(:issue_syncs, on_delete: :delete_all), null: false
    end
  end
end
