defmodule Linear.Repo.Migrations.AlterAccountsSupportGithubApps do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :github_installation_id, :string
    end
  end
end
