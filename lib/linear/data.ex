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
  alias Linear.Webhooks.{LinearWebhook, GithubWebhook}

  @doc """
  Returns the list of issue_syncs for an account.
  """
  def list_issue_syncs(account = %Account{}) do
    Repo.all from i in IssueSync,
      where: [account_id: ^account.id],
      order_by: {:desc, :inserted_at}
  end

  @doc """
  Gets a single issue_sync.

  Raises `Ecto.NoResultsError` if the Issue sync does not exist.
  """
  def get_issue_sync!(id), do: Repo.get!(IssueSync, id) |> Repo.preload([:account])

  def list_issue_syncs_by_repo_id(repo_id) do
    Repo.all from i in IssueSync,
      join: a in assoc(i, :account),
      where: i.repo_id == ^repo_id and i.enabled == true,
      preload: [account: a]
  end

  def list_issue_syncs_by_team_id(team_id) do
    Repo.all from i in IssueSync,
      join: a in assoc(i, :account),
      where: i.team_id == ^team_id and i.enabled == true,
      preload: [account: a]
  end

  @doc """
  Creates a issue_sync.
  """
  def create_issue_sync(account = %Account{}, attrs \\ %{}) do
    %IssueSync{}
    |> IssueSync.assoc_changeset(account, attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a issue_sync.
  """
  def update_issue_sync(%IssueSync{} = issue_sync, attrs) do
    issue_sync
    |> IssueSync.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Marks an issue_sync as enabled and associates webhooks.
  """
  def enable_issue_sync(
    %IssueSync{enabled: false} = issue_sync,
    %LinearWebhook{} = linear_webhook,
    %GithubWebhook{} = github_webhook
  ) do
    issue_sync
    |> Ecto.Changeset.change(enabled: true)
    |> Ecto.Changeset.put_assoc(:linear_internal_webhook, linear_webhook)
    |> Ecto.Changeset.put_assoc(:github_internal_webhook, github_webhook)
    |> Repo.update()
  end

  @doc """
  Marks an issue_sync as enabled and associates webhooks.
  """
  def disable_issue_sync(%IssueSync{enabled: true} = issue_sync) do
    issue_sync
    |> Ecto.Changeset.change(enabled: false)
    |> Ecto.Changeset.put_assoc(:linear_internal_webhook, nil)
    |> Ecto.Changeset.put_assoc(:github_internal_webhook, nil)
    |> Repo.update()
  end

  @doc """
  Deletes a issue_sync.
  """
  def delete_issue_sync(%IssueSync{} = issue_sync) do
    Repo.delete(issue_sync)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking issue_sync changes.
  """
  def change_issue_sync(%IssueSync{} = issue_sync, attrs \\ %{}) do
    IssueSync.changeset(issue_sync, attrs)
  end

  @doc """
  Gets a single ln_issue.
  """
  def get_ln_issue(id), do: Repo.get(LnIssue, id)

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
  """
  def list_ln_comments do
    Repo.all(LnComment)
  end

  @doc """
  Gets a single ln_comment.

  Raises `Ecto.NoResultsError` if the Ln comment does not exist.
  """
  def get_ln_comment!(id), do: Repo.get!(LnComment, id)

  @doc """
  Creates a ln_comment.
  """
  def create_ln_comment(ln_issue = %LnIssue{}, attrs \\ %{}) do
    %LnComment{}
    |> LnComment.assoc_changeset(ln_issue, attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a ln_comment.
  """
  def delete_ln_comment(%LnComment{} = ln_comment) do
    Repo.delete(ln_comment)
  end
end
