defmodule Linear.Data.SharedComment do
  use Ecto.Schema
  import Ecto.Changeset

  alias Linear.Data.SharedIssue
  alias Linear.Synchronize.Event

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "shared_comments" do
    # Linear data
    field :linear_comment_id, :binary_id

    # Github data
    field :github_comment_id, :integer

    # Associations
    belongs_to :shared_issue, SharedIssue

    timestamps(type: :utc_datetime)
  end

  @doc false
  def assoc_changeset(shared_comment, %Event{} = event) do
    shared_comment
    |> cast(Event.attrs(event), source_attrs(event.source))
    |> validate_required(source_attrs(event.source))
  end

  defp source_attrs(:github), do: [:github_comment_id]
  defp source_attrs(:linear), do: [:linear_comment_id]
end
