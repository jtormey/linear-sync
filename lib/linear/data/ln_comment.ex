defmodule Linear.Data.LnComment do
  use Ecto.Schema
  import Ecto.Changeset

  alias Linear.Data.LnIssue

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  schema "ln_comments" do
    field :github_comment_id, :integer

    belongs_to :ln_issue, LnIssue

    timestamps(type: :utc_datetime)
  end

  @doc false
  def assoc_changeset(ln_comment, ln_issue = %LnIssue{}, attrs) do
    ln_comment
    |> cast(attrs, [:id, :github_comment_id])
    |> validate_required([:id, :github_comment_id])
    |> put_assoc(:ln_issue, ln_issue)
  end
end
