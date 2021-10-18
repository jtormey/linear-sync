defmodule Linear.Actions.CreateGithubIssue do
  require Logger

  alias Linear.Actions.Helpers
  alias Linear.GithubAPI.GithubData, as: Gh

  @enforce_keys [:title, :body]
  defstruct [:title, :body]

  def new(fields), do: struct(__MODULE__, fields)

  def requires?(_any), do: false

  def process(%__MODULE__{} = action, %{issue_sync: issue_sync} = context) do
    {client, repo_key} = Helpers.client_repo_key(issue_sync)

    Helpers.github_api().create_issue(
      client,
      repo_key,
      %{
        "title" => action.title,
        "body" => action.body
      }
    )
    |> case do
      {201, github_issue_data, _response} ->
        github_issue = Gh.Issue.new(github_issue_data)

        context.shared_issue
        |> Helpers.update_shared_issue(github_issue)
        |> case do
          {:ok, shared_issue} ->
            context =
              context
              |> Map.put(:shared_issue, shared_issue)
              |> Map.put(:github_issue, github_issue)

            {:ok, context}

          {:error, reason} ->
            {:error, {:create_github_issue, reason}}
        end

      error ->
        Logger.error("Error creating github issue: #{inspect(error)}")
        {:error, :create_github_issue}
    end
  end
end
