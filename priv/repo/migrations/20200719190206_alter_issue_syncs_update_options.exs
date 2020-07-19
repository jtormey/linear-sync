defmodule Linear.Repo.Migrations.AlterIssueSyncsUpdateOptions do
  use Ecto.Migration

  def change do
    alter table(:issue_syncs) do
      add :assignee_id, :binary_id
      add :open_state_id, :binary_id
      add :close_state_id, :binary_id
      remove :self_assign, :boolean
      remove :state_id, :binary_id
      remove :project_id, :binary_id
    end
  end
end
