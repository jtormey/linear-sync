defmodule Linear.Webhooks do
  import Ecto.Query, warn: false

  require Logger

  alias Linear.Repo
  alias Linear.LinearAPI
  alias Linear.GithubAPI
  alias Linear.Accounts.Account
  alias Linear.Data.IssueSync
  alias Linear.Webhooks.LinearWebhook
  alias Linear.Webhooks.GithubWebhook

  alias LinearWeb.Router.Helpers, as: Routes

  @doc """
  Gets the webhook with the given scope for an issue sync, returns nil if
  none exist.
  """
  def get_webhook(:linear, %IssueSync{} = issue_sync) do
    Repo.get_by LinearWebhook,
      team_id: issue_sync.team_id
  end

  def get_webhook(:github, %IssueSync{} = issue_sync) do
    Repo.get_by GithubWebhook,
      repo_owner: issue_sync.repo_owner,
      repo_name: issue_sync.repo_name
  end

  @doc """
  Lists all webhooks associated with an account, separated by scope.
  """
  def list_webhooks(%Account{} = account) do
    query_webhooks = fn query ->
      query
      |> where(account_id: ^account.id)
      |> order_by(desc: :inserted_at)
      |> preload(:issue_syncs)
      |> Repo.all()
    end

    %{
      linear: query_webhooks.(from LinearWebhook),
      github: query_webhooks.(from GithubWebhook)
    }
  end

  @doc """
  Creates a webhook with the given scope for an issue sync. If successful, it
  means that the webhook was installed.
  """
  def create_webhook(scope, %IssueSync{} = issue_sync) do
    issue_sync = Repo.preload(issue_sync, [:account])

    Repo.transaction fn ->
      with {:ok, nil} <- {:ok, get_webhook(scope, issue_sync)},
           {:ok, webhook} <- do_create_webhook(scope, issue_sync),
           {:ok, webhook_id} <- install_webhook(scope, issue_sync),
           {:ok, webhook} <- do_update_webhook(webhook, webhook_id) do
        webhook
      else
        {:ok, webhook} ->
          webhook

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end
  end

  defp install_webhook(:linear, %IssueSync{} = issue_sync) do
    result = LinearAPI.create_webhook LinearAPI.Session.new(issue_sync.account),
      url: Routes.linear_webhook_url(LinearWeb.Endpoint, :handle),
      teamId: issue_sync.team_id

    case result do
      {:ok, %{"data" => %{"webhookCreate" => %{"success" => true, "webhook" => %{"id" => webhook_id, "enabled" => true}}}}} ->
        {:ok, webhook_id}

      error ->
        Logger.error("Failed to enable Linear webhook, #{inspect error}")
        {:error, :linear_webhook_enable_failure}
    end
  end

  defp install_webhook(:github, %IssueSync{} = issue_sync) do
    client = GithubAPI.client(issue_sync.account)
    repo_key = GithubAPI.to_repo_key!(issue_sync)

    result = GithubAPI.create_webhook client, repo_key,
      url: Routes.github_webhook_url(LinearWeb.Endpoint, :handle),
      secret: "secret" # TODO: Secure secret

    case result do
      {201, %{"active" => true, "id" => webhook_id}, _response} ->
        {:ok, webhook_id}

      {_status, error, _response} ->
        Logger.error("Failed to enable Github webhook, #{inspect error}")
        {:error, :github_webhook_enable_failure}
    end
  end

  defp do_create_webhook(:linear, %IssueSync{linear_internal_webhook_id: nil} = issue_sync) do
    attrs = Map.take(issue_sync, [:team_id])

    %LinearWebhook{}
    |> LinearWebhook.create_changeset(issue_sync.account, attrs)
    |> Repo.insert()
  end

  defp do_create_webhook(:github, %IssueSync{github_internal_webhook_id: nil} = issue_sync) do
    attrs = Map.take(issue_sync, [:repo_id, :repo_owner, :repo_name])

    %GithubWebhook{}
    |> GithubWebhook.create_changeset(issue_sync.account, attrs)
    |> Repo.insert()
  end

  defp do_update_webhook(%webhook_schema{} = webhook, webhook_id) do
    webhook
    |> webhook_schema.update_changeset(%{webhook_id: webhook_id})
    |> Repo.update()
  end

  @doc """
  Deletes a webhook. If successful, it means that the webhook was uninstalled.
  """
  def delete_webhook(nil), do: nil

  def delete_webhook(%_Webhook{} = webhook) do
    webhook = Repo.preload(webhook, [:account])

    Repo.transaction fn ->
      with :ok <- check_webhook_references(webhook),
           {:ok, _webhook} <- Repo.delete(webhook),
           :ok <- uninstall_webhook(webhook) do
        webhook
      else
        {:error, :webhook_has_references} ->
          Logger.info("Webhook has existing references, not deleting #{inspect webhook}")
          webhook

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end
  end

  defp uninstall_webhook(%LinearWebhook{} = linear_webhook) do
    result = LinearAPI.delete_webhook LinearAPI.Session.new(linear_webhook.account),
      id: linear_webhook.webhook_id

    case result do
      {:ok, %{"data" => %{"webhookDelete" => %{"success" => true}}}} ->
        :ok

      {:ok, %{"data" => nil, "errors" => [%{"message" => "Entity not found"}]}} ->
        :ok

      error ->
        Logger.error("Failed to disable Linear webhook, #{inspect error}")
        {:error, :linear_webhook_disable_failure}
    end
  end

  defp uninstall_webhook(%GithubWebhook{} = github_webhook) do
    client = GithubAPI.client(github_webhook.account)
    repo_key = GithubAPI.to_repo_key!(github_webhook)

    result = GithubAPI.delete_webhook client, repo_key,
      hook_id: github_webhook.webhook_id

    case result do
      {204, _body, _response} ->
        :ok

      {404, _body, _response} ->
        :ok

      {_status, error, _response} ->
        Logger.error("Failed to disable Github webhook, #{inspect error}")
        {:error, :github_webhook_disable_failure}
    end
  end

  @doc """
  Checks the database for issue_syncs that reference the given webhook. If any
  exist, the webhook should not be deleted.

  This is because webhooks are a shared resource that should only be uninstalled
  when all references to them have been removed.
  """
  def check_webhook_references(%_Webhook{} = webhook) do
    if webhook_has_references?(webhook), do: {:error, :webhook_has_references}, else: :ok
  end

  defp webhook_has_references?(%LinearWebhook{} = linear_webhook) do
    Repo.one from issue_sync in IssueSync,
      where: [linear_internal_webhook_id: ^linear_webhook.id],
      select: count(issue_sync) > 0
  end

  defp webhook_has_references?(%GithubWebhook{} = github_webhook) do
    Repo.one from issue_sync in IssueSync,
      where: [github_internal_webhook_id: ^github_webhook.id],
      select: count(issue_sync) > 0
  end
end
