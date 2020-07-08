defmodule Linear.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :api_key, :string

      timestamps()
    end

  end
end
