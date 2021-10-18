defmodule Linear.Data do
  @moduledoc """
  The Data context.
  """

  import Ecto.Query, warn: false
  alias Linear.Repo

  alias Linear.Accounts.Account
  alias Linear.Data.IssueSync
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

  def get_issue_sync_by!(opts), do: Repo.get_by!(IssueSync, opts) |> Repo.preload([:account])

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

  def list_issue_syncs_by_linear_issue_id(linear_issue_id) do
    Repo.all from i in IssueSync,
      join: a in assoc(i, :account),
      join: s in assoc(i, :shared_issues),
      where: s.linear_issue_id == ^linear_issue_id and i.enabled == true,
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
  Deletes all issue_syncs for an account.
  """
  def delete_disabled_issue_syncs_for_account(%Account{} = account) do
    Repo.delete_all from i in IssueSync,
      where: [account_id: ^account.id, enabled: false]
    :ok
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking issue_sync changes.
  """
  def change_issue_sync(%IssueSync{} = issue_sync, attrs \\ %{}) do
    IssueSync.changeset(issue_sync, attrs)
  end
end
