defmodule Linear.Actions.UpdateGithubIssue do
  require Logger

  alias Linear.Actions.Helpers

  @enforce_keys [:title]
  defstruct [:title]

  def new(fields), do: struct(__MODULE__, fields)

  def process(%__MODULE__{} = action, %{issue_sync: issue_sync} = context) do
    {client, repo_key} = Helpers.client_repo_key(issue_sync)

    Helpers.github_api().update_issue(
      client,
      repo_key,
      context.shared_issue.github_issue_number,
      %{
        "title" => action.title
      }
    )
    |> case do
      {200, _body, _response} ->
        {:ok, context}

      error ->
        Logger.error("Error creating github issue comment: #{inspect(error)}")

        {:error, :update_github_issue}
    end
  end
end
