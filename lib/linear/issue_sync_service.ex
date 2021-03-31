defmodule Linear.IssueSyncService do
  require Logger

  alias Linear.Repo
  alias Linear.Accounts.Account
  alias Linear.Data
  alias Linear.Data.IssueSync
  # alias Linear.LinearAPI
  alias Linear.GithubAPI
  alias LinearWeb.Router.Helpers, as: Routes

  def enable_issue_sync(account = %Account{id: id}, issue_sync = %IssueSync{account_id: id, enabled: false}) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:issue_sync, Data.change_issue_sync(issue_sync, %{enabled: true}))
    # |> Ecto.Multi.run(:linear_webhook, fn repo, multi -> enable_linear_webhook(account, repo, multi) end)
    |> Ecto.Multi.run(:github_webhook, fn repo, multi -> enable_github_webhook(account, repo, multi) end)
    |> Repo.transaction()
    |> handle_result()
  end

  def disable_issue_sync(account = %Account{id: id}, issue_sync = %IssueSync{account_id: id, enabled: true}) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:issue_sync, Data.change_issue_sync(issue_sync, %{enabled: false}))
    # |> Ecto.Multi.run(:linear_webhook, fn repo, multi -> disable_linear_webhook(account, repo, multi) end)
    |> Ecto.Multi.run(:github_webhook, fn repo, multi -> disable_github_webhook(account, repo, multi) end)
    |> Repo.transaction()
    |> handle_result()
  end

  # def enable_linear_webhook(account, repo, multi) do
  #   result = LinearAPI.create_webhook LinearAPI.Session.new(account),
  #     url: Routes.linear_webhook_url(LinearWeb.Endpoint, :handle),
  #     teamId: multi.issue_sync.team_id
  #
  #   case result do
  #     {:ok, %{"data" => %{"webhookCreate" => %{"success" => true, "webhook" => %{"id" => webhook_id, "enabled" => true}}}}} ->
  #       multi.issue_sync
  #       |> Data.change_issue_sync(%{linear_webhook_id: webhook_id})
  #       |> repo.update()
  #
  #     error ->
  #       Logger.error("Failed to enable Linear webhook, #{inspect error}")
  #       {:error, :linear_webhook_enable_failure}
  #   end
  # end

  # def disable_linear_webhook(account, repo, multi) do
  #   result = LinearAPI.delete_webhook LinearAPI.Session.new(account),
  #     id: multi.issue_sync.linear_webhook_id
  #
  #   case result do
  #     {:ok, %{"data" => %{"webhookDelete" => %{"success" => true}}}} ->
  #       multi.issue_sync
  #       |> Data.change_issue_sync(%{linear_webhook_id: nil})
  #       |> repo.update()
  #
  #     error ->
  #       Logger.error("Failed to disable Linear webhook, #{inspect error}")
  #       {:error, :linear_webhook_disable_failure}
  #   end
  # end

  def enable_github_webhook(account, repo, multi) do
    client = GithubAPI.client(account)
    repo_key = GithubAPI.to_repo_key!(multi.issue_sync)

    result = GithubAPI.create_webhook client, repo_key,
      url: Routes.github_webhook_url(LinearWeb.Endpoint, :handle),
      secret: "secret"

    case result do
      {201, %{"active" => true, "id" => webhook_id}, _response} ->
        multi.issue_sync
        |> Data.change_issue_sync(%{github_webhook_id: webhook_id})
        |> repo.update()

      {_status, error, _response} ->
        Logger.error("Failed to enable Github webhook, #{inspect error}")
        {:error, :github_webhook_enable_failure}
    end
  end

  def disable_github_webhook(account, repo, multi) do
    client = GithubAPI.client(account)
    repo_key = GithubAPI.to_repo_key!(multi.issue_sync)

    result = GithubAPI.delete_webhook client, repo_key,
      hook_id: multi.issue_sync.github_webhook_id

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
        Logger.error("Failed to disable Github webhook, #{inspect error}")
        {:error, :github_webhook_disable_failure}
    end
  end

  def handle_result({:ok, _multi}), do: :ok
  def handle_result({:error, _step, reason, _multi}), do: {:error, reason}
end
