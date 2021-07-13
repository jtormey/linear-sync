defmodule Linear.Synchronize do
  @moduledoc false

  require Logger

  alias Linear.Accounts
  alias Linear.Data
  alias Linear.LinearAPI
  alias Linear.LinearQuery
  alias Linear.GithubAPI
  alias Linear.GithubAPI.GithubData, as: Gh
  alias Linear.Synchronize.ContentWriter

  @doc """
  Given a scope, handles an incoming webhook message.
  """
  def handle_incoming(:github, %{"action" => "opened", "repository" => gh_repo} = params) do
    if gh_issue = params["issue"] || params["pull_request"] do
      handle_github_issue_opened(Gh.Repo.new(gh_repo), Gh.Issue.new(gh_issue))
    end
  end

  def handle_incoming(:github, %{"action" => "closed"} = params) do
    if gh_issue = params["issue"] || params["pull_request"] do
      handle_github_issue_closed(Gh.Issue.new(gh_issue))
    end
  end

  def handle_incoming(:github, %{"action" => "created", "comment" => gh_comment, "issue" => gh_issue}) do
    handle_github_comment_created(Gh.Issue.new(gh_issue), Gh.Comment.new(gh_comment))
  end

  def handle_incoming(:github, %{"action" => "labeled", "label" => gh_label} = params) do
    if gh_issue = params["issue"] || params["pull_request"] do
      handle_github_issue_labeled(Gh.Issue.new(gh_issue), Gh.Label.new(gh_label))
    end
  end

  def handle_incoming(:github, %{"action" => "unlabeled", "label" => gh_label} = params) do
    if gh_issue = params["issue"] || params["pull_request"] do
      handle_github_issue_unlabeled(Gh.Issue.new(gh_issue), Gh.Label.new(gh_label))
    end
  end

  def handle_incoming(:linear, %{"action" => "create", "type" => "Issue"} = params) do
    if not ln_issue_private?(params) do
      Enum.each Data.list_issue_syncs_by_team_id(params["data"]["teamId"]), fn issue_sync ->
        handle_linear_issue_created(issue_sync, params)
      end
    end
  end

  def handle_incoming(:linear, %{"action" => "update", "type" => "Issue"} = params) do
    if ln_issue = Data.get_ln_issue(params["data"]["id"]) do
      if ln_issue.github_issue_number != nil do
        handle_linear_issue_updated(ln_issue, params)
      end
    end
  end

  def handle_incoming(:linear, %{"action" => "create", "type" => "Comment"} = params) do
    if ln_issue = Data.get_ln_issue(params["data"]["issue"]["id"]) do
      if ln_issue.github_issue_number != nil do
        handle_linear_comment_created(ln_issue, params)
      end
    end
  end

  def handle_incoming(scope, params) do
    Logger.warn "Unhandled action in scope #{scope} => #{params["action"] || "?"}"
  end

  @doc """
  Handles an issue or pull request opened event.
  """
  def handle_github_issue_opened(%Gh.Repo{} = gh_repo, %Gh.Issue{} = gh_issue) do
    case parse_linear_issue_ids(gh_issue.title) do
      [] ->
        Enum.each Data.list_issue_syncs_by_repo_id(gh_repo.id), fn issue_sync ->
          create_ln_issue_from_gh_issue(issue_sync, gh_repo, gh_issue)
        end

      issue_ids ->
        Enum.each Data.list_issue_syncs_by_repo_id(gh_repo.id), fn issue_sync ->
          session = LinearAPI.Session.new(issue_sync.account)

          Enum.each issue_ids, fn issue_id ->
            with {:ok, attrs} <- LinearQuery.get_issue_by_id(session, issue_id) do
              {:ok, ln_issue} =
                if ln_issue = Data.get_ln_issue(attrs["id"]) do
                  {:ok, ln_issue}
                else
                  attrs =
                    attrs
                    |> Map.put("github_issue_id", gh_issue.id)
                    |> Map.put("github_issue_number", gh_issue.number)

                  Data.create_ln_issue(issue_sync, attrs)
                end

              Logger.info("Linked Github issue #{inspect gh_issue} with existing Linear issue #{inspect ln_issue}")

              LinearQuery.create_issue_comment(session, ln_issue, body: ContentWriter.linear_comment_issue_linked_body(gh_issue))
            end
          end
        end
    end
  end

  @doc """
  Handles an issue or pull request closed event.
  """
  def handle_github_issue_closed(%Gh.Issue{} = gh_issue) do
    Enum.each Data.list_ln_issues_by_github_issue_id(gh_issue.id), fn ln_issue ->
      if ln_issue.issue_sync.close_state_id != nil and not ln_issue.issue_sync.close_on_open do
        session = LinearAPI.Session.new(ln_issue.issue_sync.account)
        LinearQuery.update_issue(session, ln_issue, stateId: ln_issue.issue_sync.close_state_id)
      end
    end
  end

  @doc """
  Handles a comment created event.
  """
  def handle_github_comment_created(%Gh.Issue{} = gh_issue, %Gh.Comment{} = gh_comment) do
    Enum.each Data.list_ln_issues_by_github_issue_id(gh_issue.id), fn ln_issue ->
      session = LinearAPI.Session.new(ln_issue.issue_sync.account)

      args = [
        body: ContentWriter.linear_comment_body(gh_comment)
      ]

      with false <- ContentWriter.via_linear_sync?(gh_comment.body),
           {:ok, attrs} <- LinearQuery.create_issue_comment(session, ln_issue, args) do
        attrs = Map.put(attrs, "github_comment_id", gh_comment.id)
        {:ok, _ln_comment} = Data.create_ln_comment(ln_issue, attrs)
      end
    end
  end

  @doc """
  Handles an issue or pull request labeled event.
  """
  def handle_github_issue_labeled(%Gh.Issue{} = gh_issue, %Gh.Label{} = gh_label) do
    Enum.each Data.list_ln_issues_by_github_issue_id(gh_issue.id), fn ln_issue ->
      if ln_label = get_corresponding_ln_issue_label(ln_issue.issue_sync, gh_label) do
        update_ln_issue_labels(ln_issue, & &1 ++ [ln_label["id"]])
      end
    end
  end

  @doc """
  Handles an issue or pull request unlabeled event.
  """
  def handle_github_issue_unlabeled(%Gh.Issue{} = gh_issue, %Gh.Label{} = gh_label) do
    Enum.each Data.list_ln_issues_by_github_issue_id(gh_issue.id), fn ln_issue ->
      if ln_label = get_corresponding_ln_issue_label(ln_issue.issue_sync, gh_label) do
        update_ln_issue_labels(ln_issue, & &1 -- [ln_label["id"]])
      end
    end
  end

  defp update_ln_issue_labels(ln_issue, map_fun) when is_function(map_fun, 1) do
    session = LinearAPI.Session.new(ln_issue.issue_sync.account)

    with {:ok, labels} = LinearQuery.list_issue_labels(session, ln_issue) do
      label_ids = Enum.map(labels, & &1["id"])
      LinearQuery.update_issue(session, ln_issue, labelIds: map_fun.(label_ids))
    end
  end

  defp get_corresponding_ln_issue_label(issue_sync, %Gh.Label{} = gh_label) do
    session = LinearAPI.Session.new(issue_sync.account)

    with {:ok, ln_labels} <- LinearQuery.list_labels(session) do
      Enum.find ln_labels, fn ln_label ->
        labels_match?(ln_label["name"], gh_label.name) && ln_label
      end
    else
      :error ->
        nil
    end
  end

  @doc """
  Creates a Linear issue given an issue_sync and Github data.
  """
  def create_ln_issue_from_gh_issue(issue_sync, %Gh.Repo{} = gh_repo, %Gh.Issue{} = gh_issue) do
    session = LinearAPI.Session.new(issue_sync.account)

    args = [
      teamId: issue_sync.team_id,
      title: ContentWriter.linear_issue_title(gh_repo, gh_issue),
      description: ContentWriter.linear_issue_body(gh_repo, gh_issue)
    ]

    args = if issue_sync.open_state_id != nil do
      Keyword.put(args, :stateId, issue_sync.open_state_id)
    else
      args
    end

    args = if issue_sync.label_id != nil do
      Keyword.put(args, :labelIds, [issue_sync.label_id])
    else
      args
    end

    args = if issue_sync.assignee_id != nil do
      Keyword.put(args, :assigneeId, issue_sync.assignee_id)
    else
      args
    end

    with false <- ContentWriter.via_linear_sync?(gh_issue.body),
         {:ok, attrs} <- LinearQuery.create_issue(session, args) do
      attrs =
        attrs
        |> Map.put("github_issue_id", gh_issue.id)
        |> Map.put("github_issue_number", gh_issue.number)

      {:ok, ln_issue} = Data.create_ln_issue(issue_sync, attrs)

      client = GithubAPI.client(Accounts.get_account!(issue_sync.account_id))
      repo_key = GithubAPI.to_repo_key!(issue_sync)

      GithubAPI.update_issue(client, repo_key, gh_issue.number, %{
        "title" => format_issue_key(attrs) <> " " <> gh_issue.title
      })

      if issue_sync.close_on_open do
        comment = ContentWriter.github_issue_moved_comment_body(ln_issue)

        GithubAPI.create_issue_comment(client, repo_key, gh_issue.number, comment)
        GithubAPI.close_issue(client, repo_key, gh_issue.number)
      end
    end
  end

  defp format_issue_key(%{"number" => issue_number, "team" => %{"key" => team_key}}) do
    "[#{team_key}-#{issue_number}]"
  end

  @doc """
  """
  def handle_linear_issue_created(issue_sync, params) do
    repo_key = GithubAPI.to_repo_key!(issue_sync)
    client = GithubAPI.client(Accounts.get_account!(issue_sync.account_id))

    attrs =
      params["data"]
      |> Map.put("url", params["url"])

    if params["description"] == nil or not ContentWriter.via_linear_sync?(params["description"]) do
      {201, gh_issue, _response} =
        GithubAPI.create_issue(client, repo_key, %{
          "title" => format_issue_key(attrs) <> " " <> attrs["title"],
          "body" => ContentWriter.github_issue_body(attrs)
        })

      gh_issue = Gh.Issue.new(gh_issue)

      attrs =
        attrs
        |> Map.put("github_issue_id", gh_issue.id)
        |> Map.put("github_issue_number", gh_issue.number)

      {:ok, _ln_issue} = Data.create_ln_issue(issue_sync, attrs)
    end
  end

  @doc """
  Diffs an incoming Linear issue and syncs updates to Github.
  """
  def handle_linear_issue_updated(ln_issue, params) do
    issue_sync = Data.get_issue_sync!(ln_issue.issue_sync_id)

    session = LinearAPI.Session.new(issue_sync.account)

    repo_key = GithubAPI.to_repo_key!(issue_sync)
    client = GithubAPI.client(Accounts.get_account!(issue_sync.account_id))

    with %{"data" => %{"labelIds" => current_label_ids}, "updatedFrom" => %{"labelIds" => prev_label_ids}} <- params,
         {:ok, ln_labels} <- LinearQuery.list_labels(session),
         {200, repo_labels, _response} <- GithubAPI.list_repository_labels(client, repo_key),
         {200, issue_labels, _response} <- GithubAPI.list_issue_labels(client, repo_key, ln_issue.github_issue_number) do
      issue_label_ids = Enum.map(issue_labels, & &1["id"])

      added_ln_labels = current_label_ids -- prev_label_ids
      removed_ln_labels = prev_label_ids -- current_label_ids

      to_add = Enum.filter repo_labels, fn repo_label ->
        if ln_label = Enum.find(ln_labels, &labels_match?(&1["name"], repo_label["name"])) do
          ln_label["id"] in added_ln_labels and repo_label["id"] not in issue_label_ids
        end
      end

      to_remove = Enum.filter repo_labels, fn repo_label ->
        if ln_label = Enum.find(ln_labels, &labels_match?(&1["name"], repo_label["name"])) do
          ln_label["id"] in removed_ln_labels and repo_label["id"] in issue_label_ids
        end
      end

      Logger.info("Adding Github labels: #{inspect to_add}")
      Logger.info("Removing Github labels: #{inspect to_remove}")

      if to_add != [] do
        GithubAPI.add_issue_labels(client, repo_key, ln_issue.github_issue_number, Enum.map(to_add, & &1["name"]))
      end

      Enum.each(to_remove, &GithubAPI.remove_issue_labels(client, repo_key, ln_issue.github_issue_number, &1["name"]))
    end

    with %{"data" => %{"stateId" => current_state_id} = data, "updatedFrom" => %{"stateId" => _prev_state_id}} <- params do
      canceled? = get_in(data, ["state", "type"]) == "canceled"

      if current_state_id == issue_sync.close_state_id or canceled? do
        GithubAPI.close_issue(client, repo_key, ln_issue.github_issue_number)
      end
    end
  end

  @doc """
  Conditionally syncs a comment from Linear to Github.
  """
  def handle_linear_comment_created(ln_issue, %{"data" => comment_data}) do
    if not ContentWriter.via_linear_sync?(comment_data["body"]) do
      issue_sync = Data.get_issue_sync!(ln_issue.issue_sync_id)

      session = LinearAPI.Session.new(issue_sync.account)

      if not ln_issue_private?(session, ln_issue) do
        repo_key = GithubAPI.to_repo_key!(issue_sync)
        client = GithubAPI.client(Accounts.get_account!(issue_sync.account_id))

        comment = ContentWriter.github_issue_comment_body(ln_issue, comment_data["body"])
        GithubAPI.create_issue_comment(client, repo_key, ln_issue.github_issue_number, comment)
      end
    end
  end

  defp ln_issue_private?(%{"data" => issue_data}) do
    issue_data["labels"] != nil and Enum.any?(issue_data["labels"], &labels_match?(&1["name"], "private"))
  end

  defp ln_issue_private?(session, ln_issue) do
    {:ok, labels} = LinearQuery.list_issue_labels(session, ln_issue)
    Enum.any?(labels, &labels_match?(&1["name"], "private"))
  end

  @doc """
  Parses Linear issue identifiers from a binary.

  ## Examples

    iex> parse_linear_issue_ids("[LN-93] My Github issue")
    ["[LN-93]"]

  """
  def parse_linear_issue_ids(title) when is_binary(title) do
    Regex.scan(~r/\[([A-Z0-9]+-\d+)\]/, title) |> Enum.map(&List.last/1)
  end

  @doc """
  Checks if two labels are equal, uses a case-insensitive comparison.
  """
  def labels_match?(label_a, label_b) do
    String.downcase(label_a) == String.downcase(label_b)
  end
end
