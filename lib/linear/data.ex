defmodule Linear.Data do
  @moduledoc """
  The Data context.
  """

  import Ecto.Query, warn: false
  alias Linear.Repo

  alias Linear.Accounts.Account
  alias Linear.Data.IssueSync
  alias Linear.Data.LnIssue
  alias Linear.Data.LnComment

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

  def list_issue_syncs_by_repo_id(repo_id) do
    Repo.all from i in IssueSync,
      join: a in assoc(i, :account),
      where: i.repo_id == ^repo_id and i.enabled == true,
      preload: [account: a]
  end

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

  def list_ln_issues_by_github_issue_id(github_issue_id) do
    Repo.all from l in LnIssue,
      join: i in assoc(l, :issue_sync),
      join: a in assoc(i, :account),
      where: l.github_issue_id == ^github_issue_id and i.enabled == true,
      preload: [issue_sync: {i, account: a}]
  end

  def create_ln_issue(issue_sync = %IssueSync{}, attrs \\ %{}) do
    %LnIssue{}
    |> LnIssue.assoc_changeset(issue_sync, attrs)
    |> Repo.insert()
  end

  @doc """
  Returns the list of ln_comments.

  ## Examples

      iex> list_ln_comments()
      [%LnComment{}, ...]

  """
  def list_ln_comments do
    Repo.all(LnComment)
  end

  @doc """
  Gets a single ln_comment.

  Raises `Ecto.NoResultsError` if the Ln comment does not exist.

  ## Examples

      iex> get_ln_comment!(123)
      %LnComment{}

      iex> get_ln_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ln_comment!(id), do: Repo.get!(LnComment, id)

  @doc """
  Creates a ln_comment.

  ## Examples

      iex> create_ln_comment(%{field: value})
      {:ok, %LnComment{}}

      iex> create_ln_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ln_comment(ln_issue = %LnIssue{}, attrs \\ %{}) do
    %LnComment{}
    |> LnComment.assoc_changeset(ln_issue, attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a ln_comment.

  ## Examples

      iex> delete_ln_comment(ln_comment)
      {:ok, %LnComment{}}

      iex> delete_ln_comment(ln_comment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ln_comment(%LnComment{} = ln_comment) do
    Repo.delete(ln_comment)
  end
end
