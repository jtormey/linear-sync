defmodule Linear.Actions.AddGithubLabels do
  alias Linear.Actions.Helpers

  @enforce_keys [:labels]
  defstruct [:labels]

  def new(fields), do: struct(__MODULE__, fields)

  def process(%__MODULE__{labels: []}, context), do: {:ok, context}

  def process(%__MODULE__{} = action, %{issue_sync: issue_sync} = context) do
    {client, repo_key} = Helpers.client_repo_key(issue_sync)

    Helpers.github_api().add_issue_labels(
      client,
      repo_key,
      context.shared_issue.github_issue_number,
      action.labels
    )
    |> case do
      {200, _body, _response} ->
        {:ok, context}

      _otherwise ->
        {:error, :add_github_labels}
    end
  end
end
