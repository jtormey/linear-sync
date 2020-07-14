defmodule Linear.Repo.Migrations.CreateLnIssues do
  use Ecto.Migration

  def change do
    create table(:ln_issues) do
      add :number, :integer, null: false
      add :title, :string, null: false
      add :description, :string
      add :url, :string, null: false
      add :public_entry_id, references(:public_entries, on_delete: :delete_all), null: false

      timestamps()
    end
  end
end
