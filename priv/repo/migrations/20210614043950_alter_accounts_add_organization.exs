defmodule Linear.Repo.Migrations.AlterAccountsAddOrganization do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :organization_id, :uuid
    end

    create unique_index(:accounts, [:organization_id])
  end
end
