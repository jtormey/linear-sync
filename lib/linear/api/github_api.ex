defmodule Linear.GithubAPI do
  @behaviour __MODULE__.Behaviour

  alias Tentacat.Client
  alias Linear.Accounts.Account

  @webhook_events ["issues", "issue_comment", "pull_request"]

  def client(account = %Account{}) do
    Tentacat.Client.new(%{access_token: account.github_token})
  end

  def to_repo_key!(%{repo_owner: repo_owner, repo_name: repo_name})
      when is_binary(repo_owner) and is_binary(repo_name),
      do: {repo_owner, repo_name}

  def user_id_by_username(username) when is_binary(username) do
    case Tentacat.Users.find(username) do
      {200, %{"id" => user_id}, _response} ->
        {:ok, user_id}

      {404, _body, _response} ->
        {:error, :not_found}
    end
  end

  @impl true
  def viewer(client = %Client{}) do
    {200, result, _response} = Tentacat.Users.me(client)
    result
  end

  @impl true
  def create_issue(client = %Client{}, {owner, repo}, params) do
    params = Map.take(params, ["title", "body"])
    Tentacat.Issues.create(client, owner, repo, params)
  end

  @impl true
  def close_issue(client = %Client{}, {owner, repo}, issue_number) do
    Tentacat.Issues.update(client, owner, repo, issue_number, %{"state" => "closed"})
  end

  @impl true
  def update_issue(client = %Client{}, {owner, repo}, issue_number, params) do
    params = Map.take(params, ["title", "state"])
    Tentacat.Issues.update(client, owner, repo, issue_number, params)
  end

  @impl true
  def list_repository_labels(client = %Client{}, {owner, repo}) do
    Tentacat.Repositories.Labels.list(client, owner, repo)
  end

  @impl true
  def list_issue_labels(client = %Client{}, {owner, repo}, issue_number) do
    Tentacat.Issues.Labels.list(client, owner, repo, issue_number)
  end

  @impl true
  def add_issue_labels(client = %Client{}, {owner, repo}, issue_number, label_ids) do
    Tentacat.Issues.Labels.add(client, owner, repo, issue_number, label_ids)
  end

  @impl true
  def remove_issue_labels(client = %Client{}, {owner, repo}, issue_number, label_id) do
    Tentacat.Issues.Labels.remove(client, owner, repo, issue_number, label_id)
  end

  @impl true
  def create_issue_comment(client = %Client{}, {owner, repo}, issue_number, body) do
    Tentacat.Issues.Comments.create(client, owner, repo, issue_number, %{"body" => body})
  end

  @impl true
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

  @impl true
  def delete_webhook(client = %Client{}, {owner, repo}, opts) do
    Tentacat.Hooks.remove(client, owner, repo, Keyword.fetch!(opts, :hook_id))
  end
end
