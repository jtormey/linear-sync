defmodule Linear.Repo.Migrations.AlterAccountsAddGithubFields do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :github_token, :string
      add :github_link_state, :string
    end
  end
end
