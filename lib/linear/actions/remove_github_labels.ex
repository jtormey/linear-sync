defmodule Linear.Actions.RemoveGithubLabels do
  alias Linear.Actions.Helpers
  alias Linear.GithubAPI.GithubData, as: Gh

  @enforce_keys [:label_ids]
  defstruct [:label_ids]

  def new(fields), do: struct(__MODULE__, fields)

  def requires?(dep), do: dep == :github

  def process(%__MODULE__{label_ids: []}, context), do: {:ok, context}

  def process(%__MODULE__{} = action, context) do
    repo_labels = Map.fetch!(context, :github_repo_labels)
    issue_label_ids = Map.fetch!(context, :github_issue_labels) |> Enum.map(& &1.id)
    linear_labels = Map.fetch!(context, :linear_labels)

    repo_labels_to_remove =
      Enum.filter(repo_labels, fn %Gh.Label{} = repo_label ->
        if ln_label =
             Enum.find(linear_labels, &Helpers.Labels.labels_match?(&1.name, repo_label.name)) do
          ln_label.id in action.label_ids and repo_label.id in issue_label_ids
        end
      end)

    Enum.reduce_while(repo_labels_to_remove, {:ok, context}, &process_label/2)
  end

  defp process_label(github_label, {:ok, %{issue_sync: issue_sync} = context}) do
    {client, repo_key} = Helpers.client_repo_key(issue_sync)

    Helpers.github_api().remove_issue_labels(
      client,
      repo_key,
      context.shared_issue.github_issue_number,
      github_label.name
    )
    |> case do
      {200, _body, _response} ->
        {:cont, {:ok, context}}

      _otherwise ->
        {:halt, {:error, :add_github_labels}}
    end
  end
end
