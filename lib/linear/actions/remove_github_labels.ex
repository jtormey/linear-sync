defmodule Linear.Actions.RemoveGithubLabels do
  alias Linear.Actions.Helpers

  @enforce_keys [:labels]
  defstruct [:labels]

  def new(fields), do: struct(__MODULE__, fields)

  def process(%__MODULE__{labels: []}, context), do: {:ok, context}

  def process(%__MODULE__{} = action, context) do
    Enum.reduce_while(action.labels, {:ok, context}, &process_label/2)
  end

  defp process_label(label_id, {:ok, %{issue_sync: issue_sync} = context}) do
    {client, repo_key} = Helpers.client_repo_key(issue_sync)

    Helpers.github_api().remove_issue_labels(
      client,
      repo_key,
      context.shared_issue.github_issue_number,
      label_id
    )
    |> case do
      {200, _body, _response} ->
        {:cont, {:ok, context}}

      _otherwise ->
        {:halt, {:error, :add_github_labels}}
    end
  end
end
