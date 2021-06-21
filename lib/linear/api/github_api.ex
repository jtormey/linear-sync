defmodule Linear.GithubAPI do
  alias Tentacat.Client
  alias Linear.Accounts.Account

  @webhook_events ["issues", "issue_comment", "pull_request"]

  def client(account = %Account{}) do
    Tentacat.Client.new(%{access_token: account.github_token})
  end

  def to_repo_key!(%{repo_owner: repo_owner, repo_name: repo_name})
    when is_binary(repo_owner) and is_binary(repo_name),
    do: {repo_owner, repo_name}

  def viewer(client = %Client{}) do
    {200, result, _response} = Tentacat.Users.me(client)
    result
  end

  def close_issue(client = %Client{}, {owner, repo}, issue_number) do
    Tentacat.Issues.update(client, owner, repo, issue_number, %{"state" => "closed"})
  end

  def update_issue(client = %Client{}, {owner, repo}, issue_number, params) do
    params = Map.take(params, ["title"])
    Tentacat.Issues.update(client, owner, repo, issue_number, params)
  end

  def create_issue_comment(client = %Client{}, {owner, repo}, issue_number, body) do
    Tentacat.Issues.Comments.create(client, owner, repo, issue_number, %{"body" => body})
  end

  def create_webhook(client = %Client{}, {owner, repo}, opts) do
    Tentacat.Hooks.create(client, owner, repo, %{
      "name" => "web",
      "active" => true,
      "events" => @webhook_events,
      "config" => %{
        "url" => Keyword.fetch!(opts, :url),
        "secret" => Keyword.fetch!(opts, :secret),
        "content_type" => "json"
      }
    })
  end

  def delete_webhook(client = %Client{}, {owner, repo}, opts) do
    Tentacat.Hooks.remove(client, owner, repo, Keyword.fetch!(opts, :hook_id))
  end
end
