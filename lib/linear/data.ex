defmodule Linear.Data do
  @moduledoc """
  The Data context.
  """

  import Ecto.Query, warn: false
  alias Linear.Repo

  alias Linear.Accounts.Account
  alias Linear.Data.IssueSync
  alias Linear.Data.LnIssue

  @doc """
  Returns the list of issue_syncs for an account.

  ## Examples

      iex> list_issue_syncs(account)
      [%IssueSync{}, ...]

  """
  def list_issue_syncs(account = %Account{}) do
    Repo.all from i in IssueSync,
      where: [account_id: ^account.id],
      order_by: {:desc, :inserted_at}
  end

  @doc """
  Gets a single issue_sync.

  Raises `Ecto.NoResultsError` if the Issue sync does not exist.

  ## Examples

      iex> get_issue_sync!(123)
      %IssueSync{}

      iex> get_issue_sync!(456)
      ** (Ecto.NoResultsError)

  """
  def get_issue_sync!(id), do: Repo.get!(IssueSync, id)

  @doc """
  Creates a issue_sync.

  ## Examples

      iex> create_issue_sync(%{field: value})
      {:ok, %IssueSync{}}

      iex> create_issue_sync(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_issue_sync(account = %Account{}, attrs \\ %{}) do
    %IssueSync{}
    |> IssueSync.assoc_changeset(account, attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a issue_sync.

  ## Examples

      iex> update_issue_sync(issue_sync, %{field: new_value})
      {:ok, %IssueSync{}}

      iex> update_issue_sync(issue_sync, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_issue_sync(%IssueSync{} = issue_sync, attrs) do
    issue_sync
    |> IssueSync.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a issue_sync.

  ## Examples

      iex> delete_issue_sync(issue_sync)
      {:ok, %IssueSync{}}

      iex> delete_issue_sync(issue_sync)
      {:error, %Ecto.Changeset{}}

  """
  def delete_issue_sync(%IssueSync{} = issue_sync) do
    Repo.delete(issue_sync)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking issue_sync changes.

  ## Examples

      iex> change_issue_sync(issue_sync)
      %Ecto.Changeset{data: %IssueSync{}}

  """
  def change_issue_sync(%IssueSync{} = issue_sync, attrs \\ %{}) do
    IssueSync.changeset(issue_sync, attrs)
  end

  def create_ln_issue(issue_sync = %IssueSync{}, attrs \\ %{}) do
    %LnIssue{}
    |> LnIssue.assoc_changeset(issue_sync, attrs)
    |> Repo.insert()
  end
end
