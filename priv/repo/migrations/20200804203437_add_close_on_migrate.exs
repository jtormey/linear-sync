defmodule Linear.Repo.Migrations.AddCloseOnMigrate do
  use Ecto.Migration

  def change do
    alter table(:issue_syncs) do
      add :close_on_open, :boolean, null: false, default: false
    end
  end
end
