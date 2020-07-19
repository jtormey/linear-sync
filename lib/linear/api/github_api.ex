defmodule Linear.GithubAPI do
  alias Tentacat.Client
  alias Linear.Accounts.Account
  alias Linear.Data.IssueSync

  @webhook_events ["issues", "issue_comment"]

  def client(account = %Account{}) do
    Tentacat.Client.new(%{access_token: account.github_token})
  end

  def to_repo_key!(issue_sync = %IssueSync{}) do
    {issue_sync.repo_owner, issue_sync.repo_name}
  end

  def viewer(client = %Client{}) do
    {200, result, _response} = Tentacat.Users.me(client)
    result
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
