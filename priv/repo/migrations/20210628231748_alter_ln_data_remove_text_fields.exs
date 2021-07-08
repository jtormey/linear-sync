defmodule Linear.Repo.Migrations.AlterLnDataRemoveTextFields do
  use Ecto.Migration

  def change do
    alter table(:ln_issues) do
      remove :title, :string
      remove :description, :text
    end

    alter table(:ln_comments) do
      remove :body, :text
    end
  end
end
