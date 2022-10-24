defmodule Linear.IssueSyncService do
  require Logger

  alias Linear.Repo
  alias Linear.Accounts.Account
  alias Linear.Data
  alias Linear.Data.IssueSync
  alias Linear.LinearAPI
  alias Linear.GithubAPI
  alias Linear.Webhooks

  @doc """
  Enables an issue_sync, handles webhook installation logic.
  """
  def enable_issue_sync(%IssueSync{} = issue_sync) do
    issue_sync =
      Repo.preload(issue_sync, [
        :account,
        :linear_internal_webhook,
        :github_internal_webhook
      ])

    Repo.transaction(fn ->
      with :ok <- disable_issue_sync_legacy(issue_sync.account, issue_sync),
           {:ok, linear_webhook} <- Webhooks.create_webhook(:linear, issue_sync),
           {:ok, github_webhook} <- Webhooks.create_webhook(:github, issue_sync),
           {:ok, issue_sync} <- Data.enable_issue_sync(issue_sync, linear_webhook, github_webhook) do
        issue_sync
      else
        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Disables all issue syncs for an account. Returns :ok if all were disabled
  and {:error, reason} in case that one fails.

  Note that this operation is not atomic.
  """
  def disable_issue_syncs_for_account(%Account{} = account) do
    account = Repo.preload(account, :issue_syncs)

    Enum.reduce_while(account.issue_syncs, :ok, fn issue_sync, :ok ->
      with %IssueSync{enabled: true} <- issue_sync,
           {:ok, _issue_sync} <- disable_issue_sync(issue_sync) do
        {:cont, :ok}
      else
        %IssueSync{enabled: false} ->
          {:cont, :ok}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  @doc """
  Disables an issue_sync, handles webhook uninstallation logic.
  """
  def disable_issue_sync(%IssueSync{} = issue_sync) do
    issue_sync =
      Repo.preload(issue_sync, [
        :account,
        :linear_internal_webhook,
        :github_internal_webhook
      ])

    Repo.transaction(fn ->
      with :ok <- disable_issue_sync_legacy(issue_sync.account, issue_sync),
           %{linear_internal_webhook: linear_internal_webhook} <- issue_sync,
           %{github_internal_webhook: github_internal_webhook} <- issue_sync,
           {:ok, issue_sync} <- Data.disable_issue_sync(issue_sync),
           {:ok, _linear_webhook} <- Webhooks.delete_webhook(linear_internal_webhook, issue_sync),
           {:ok, _github_webhook} <- Webhooks.delete_webhook(github_internal_webhook, issue_sync) do
        issue_sync
      else
        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  # Legacy webhook handling functions, webhooks are now fully handled in
  # the Linear.Webhooks context.

  defp disable_issue_sync_legacy(
         account = %Account{id: id},
         issue_sync = %IssueSync{account_id: id}
       ) do
    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.update(:issue_sync, Data.change_issue_sync(issue_sync, %{enabled: false}))

    multi =
      if issue_sync.linear_webhook_id != nil do
        multi
        |> Ecto.Multi.run(:linear_webhook, fn repo, multi ->
          disable_linear_webhook(account, repo, multi)
        end)
      else
        multi
      end

    multi =
      if issue_sync.github_webhook_id != nil do
        multi
        |> Ecto.Multi.run(:github_webhook, fn repo, multi ->
          disable_github_webhook(account, repo, multi)
        end)
      else
        multi
      end

    multi
    |> Repo.transaction()
    |> handle_result()
  end

  defp disable_linear_webhook(account, repo, multi) do
    result =
      LinearAPI.delete_webhook(LinearAPI.Session.new(account),
        id: multi.issue_sync.linear_webhook_id
      )

    do_disable = fn ->
      multi.issue_sync
      |> Data.change_issue_sync(%{linear_webhook_id: nil})
      |> repo.update()
    end

    case result do
      {:ok, %{"data" => %{"webhookDelete" => %{"success" => true}}}} ->
        do_disable.()

      {:ok, %{"data" => nil, "errors" => [%{"message" => "Entity not found"}]}} ->
        do_disable.()

      error ->
        Logger.error("Failed to disable Linear webhook, #{inspect(error)}")
        {:error, :linear_webhook_disable_failure}
    end
  end

  defp disable_github_webhook(account, repo, multi) do
    client = GithubAPI.client(account)
    repo_key = GithubAPI.to_repo_key!(multi.issue_sync)

    result =
      GithubAPI.delete_webhook(client, repo_key, hook_id: multi.issue_sync.github_webhook_id)

    do_disable = fn ->
      multi.issue_sync
      |> Data.change_issue_sync(%{github_webhook_id: nil})
      |> repo.update()
    end

    case result do
      {204, _body, _response} ->
        do_disable.()

      {404, _body, _response} ->
        do_disable.()

      {_status, error, _response} ->
        Logger.error("Failed to disable Github webhook, #{inspect(error)}")
        {:error, :github_webhook_disable_failure}
    end
  end

  defp handle_result({:ok, _multi}), do: :ok
  defp handle_result({:error, _step, reason, _multi}), do: {:error, reason}
end
