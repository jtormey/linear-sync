defmodule Linear.Data.SharedIssue do
  use Ecto.Schema
  import Ecto.Changeset

  alias Linear.Data.IssueSync
  alias Linear.Data.SharedComment
  alias Linear.Synchronize.Event

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "shared_issues" do
    # Linear data
    field :linear_issue_id, :binary_id
    field :linear_issue_number, :integer

    # Github data
    field :github_issue_id, :integer
    field :github_issue_number, :integer

    # Associations
    belongs_to :issue_sync, IssueSync
    has_many :shared_comments, SharedComment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def event_changeset(shared_issue, %Event{} = event) do
    shared_issue
    |> cast(Event.attrs(event), source_attrs(event.source))
    |> validate_required(source_attrs(event.source))
    |> unique_constraint(:linear_issue_id)
    |> unique_constraint(:github_issue_id)
  end

  defp source_attrs(:github), do: [:issue_sync_id, :github_issue_id, :github_issue_number]
  defp source_attrs(:linear), do: [:issue_sync_id, :linear_issue_id, :linear_issue_number]
end
