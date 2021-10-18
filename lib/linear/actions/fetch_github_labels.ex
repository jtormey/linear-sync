defmodule Linear.Actions.FetchGithubLabels do
  require Logger

  alias Linear.Actions.Helpers
  alias Linear.GithubAPI.GithubData, as: Gh

  @enforce_keys []
  defstruct []

  def new(fields \\ %{}), do: struct(__MODULE__, fields)

  def requires?(dep), do: dep == :github

  def process(%__MODULE__{}, %{issue_sync: issue_sync} = context) do
    {client, repo_key} = Helpers.client_repo_key(issue_sync)

    with {200, repo_labels, _response} <-
           Helpers.github_api().list_repository_labels(client, repo_key),
         {200, issue_labels, _response} <-
           Helpers.github_api().list_issue_labels(
             client,
             repo_key,
             context.shared_issue.github_issue_number
           ) do
      context =
        Map.merge(context, %{
          github_repo_labels: Enum.map(repo_labels, &Gh.Label.new/1),
          github_issue_labels: Enum.map(issue_labels, &Gh.Label.new/1)
        })

      {:ok, context}
    else
      error ->
        Logger.error("Error fetching github labels: #{inspect(error)}")

        {:error, :fetch_github_labels}
    end
  end
end
