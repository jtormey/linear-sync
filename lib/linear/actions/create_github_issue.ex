defmodule Linear.Actions.CreateGithubIssue do
  require Logger

  alias Linear.Repo
  alias Linear.Actions.Helpers
  alias Linear.GithubAPI.GithubData, as: Gh

  @enforce_keys [:title, :body]
  defstruct [:title, :body]

  def new(fields), do: struct(__MODULE__, fields)

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
        context =
          Map.update!(
            context,
            :shared_issue,
            &update_shared_issue!(&1, Gh.Issue.new(github_issue_data))
          )

        {:ok, context}

      error ->
        Logger.error("Error creating github issue: #{inspect(error)}")

        {:error, :create_github_issue}
    end
  end

  defp update_shared_issue!(shared_issue, %Gh.Issue{} = github_issue) do
    shared_issue
    |> Ecto.Changeset.change(
      github_issue_id: github_issue.id,
      github_issue_number: github_issue.number
    )
    |> Repo.update!()
  end
end
