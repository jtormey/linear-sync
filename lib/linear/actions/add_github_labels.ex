defmodule Linear.Actions.AddGithubLabels do
  alias Linear.Actions.Helpers
  alias Linear.GithubAPI.GithubData, as: Gh

  @enforce_keys [:label_ids]
  defstruct [:label_ids]

  def new(fields), do: struct(__MODULE__, fields)

  def requires?(dep), do: dep == :github

  def process(%__MODULE__{label_ids: []}, context), do: {:ok, context}

  def process(%__MODULE__{} = action, %{issue_sync: issue_sync} = context) do
    repo_labels = Map.fetch!(context, :github_repo_labels)
    issue_label_ids = Map.fetch!(context, :github_issue_labels) |> Enum.map(& &1.id)
    linear_labels = Map.fetch!(context, :linear_labels)

    repo_labels_to_add =
      Enum.filter(repo_labels, fn %Gh.Label{} = repo_label ->
        if ln_label = Enum.find(linear_labels, &Helpers.Labels.labels_match?(&1.name, repo_label.name)) do
          ln_label.id in action.label_ids and repo_label.id not in issue_label_ids
        end
      end)

    {client, repo_key} = Helpers.client_repo_key(issue_sync)

    Helpers.github_api().add_issue_labels(
      client,
      repo_key,
      context.shared_issue.github_issue_number,
      Enum.map(repo_labels_to_add, & &1.name)
    )
    |> case do
      {200, _body, _response} ->
        {:ok, context}

      _otherwise ->
        {:error, :add_github_labels}
    end
  end
end
