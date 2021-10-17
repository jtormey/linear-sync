defmodule Linear.Data.SharedIssueLock do
  use Ecto.Schema
  import Ecto.Changeset

  alias Linear.Repo
  alias Linear.Data.SharedIssue

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "shared_issue_locks" do
    field :expires_at, :utc_datetime
    belongs_to :shared_issue, SharedIssue

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Acquires a lock on a shared_issue record.
  """
  def acquire(%SharedIssue{} = shared_issue) do
    %__MODULE__{}
    |> acquire_changeset(shared_issue)
    |> Repo.insert()
  end

  @doc """
  Releases a shared_issue_lock.
  """
  def release(%__MODULE__{} = shared_issue_lock) do
    Repo.delete(shared_issue_lock)
  end

  defp acquire_changeset(shared_issue_lock, %SharedIssue{} = shared_issue) do
    shared_issue_lock
    |> change(shared_issue_id: shared_issue.id)
    |> unique_constraint(:shared_issue_id, message: "issue is currently locked")
  end
end
