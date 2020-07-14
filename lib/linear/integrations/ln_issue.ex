defmodule Linear.Integrations.LnIssue do
  use Ecto.Schema
  import Ecto.Changeset

  alias Linear.Integrations.PublicEntry

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  schema "ln_issues" do
    field :description, :string
    field :number, :integer
    field :title, :string
    field :url, :string

    belongs_to :public_entry, PublicEntry

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(ln_issue, public_entry = %PublicEntry{}, attrs) do
    ln_issue
    |> cast(attrs, [:id, :number, :title, :description, :url])
    |> validate_required([:id, :number, :title, :url])
    |> put_assoc(:public_entry, public_entry)
  end
end
