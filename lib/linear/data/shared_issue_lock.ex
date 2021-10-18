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
  Acquires a lock on a shared_issue record by polling every second.
  """
  def acquire(%SharedIssue{} = shared_issue, opts \\ []) do
    do_acquire(shared_issue, Keyword.fetch!(opts, :max_attempts))
  end

  defp do_acquire(shared_issue, max_attempts) do
    case {acquire_now(shared_issue), max_attempts - 1} do
      {{:ok, _lock} = result, _attempts_remaining} ->
        result

      {{:error, _reason} = error, 0} ->
        error

      {{:error, _reason}, attempts_remaining} ->
        Process.sleep(1000)
        do_acquire(shared_issue, attempts_remaining)
    end
  end

  @doc """
  Acquires a lock on a shared_issue record with no retries.
  """
  def acquire_now(%SharedIssue{} = shared_issue) do
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
    |> change(shared_issue_id: shared_issue.id, expires_at: Date)
    |> put_expires_at(in_seconds: 30)
    |> unique_constraint(:shared_issue_id, message: "issue is currently locked")
  end

  defp put_expires_at(changeset, opts) do
    expires_in = Keyword.fetch!(opts, :in_seconds)
    expires_at = DateTime.add(DateTime.utc_now(), expires_in, :second)
    expires_at = expires_at |> DateTime.truncate(:second)
    put_change(changeset, :expires_at, expires_at)
  end
end
