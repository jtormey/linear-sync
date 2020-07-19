defmodule Linear.Data.LnIssue do
  use Ecto.Schema
  import Ecto.Changeset

  alias Linear.Data.IssueSync
  alias Linear.Data.LnComment

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  schema "ln_issues" do
    field :description, :string
    field :number, :integer
    field :title, :string
    field :url, :string
    field :github_issue_id, :integer

    belongs_to :issue_sync, IssueSync
    has_many :ln_comments, LnComment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def assoc_changeset(ln_issue, issue_sync = %IssueSync{}, attrs) do
    ln_issue
    |> cast(attrs, [:id, :number, :title, :description, :url, :github_issue_id])
    |> validate_required([:id, :number, :title, :url, :github_issue_id])
    |> put_assoc(:issue_sync, issue_sync)
  end
end
