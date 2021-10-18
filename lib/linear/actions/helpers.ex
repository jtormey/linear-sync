defmodule Linear.Actions.Helpers do
  import Ecto.Query, warn: false

  alias Linear.Repo
  alias Linear.GithubAPI
  alias Linear.Data.IssueSync
  alias Linear.Data.SharedIssue
  alias Linear.GithubAPI.GithubData, as: Gh
  alias Linear.LinearAPI.LinearData, as: Ln

  @doc """
  """
  def client_repo_key(%IssueSync{} = issue_sync) do
    issue_sync = Repo.preload(issue_sync, :account)
    {GithubAPI.client(issue_sync.account), GithubAPI.to_repo_key!(issue_sync)}
  end

  # TODO: Replace with dispatch module
  def github_api() do
    Application.get_env(:linear, :github_api, GithubAPI)
  end

  @doc """
  """
  def combine_actions(actions) do
    Enum.flat_map(List.wrap(actions), fn
      nil ->
        []

      actions ->
        List.wrap(actions)
    end)
  end

  @doc """
  """
  def update_shared_issue(shared_issue, %Gh.Issue{} = github_issue) do
    shared_issue
    |> Ecto.Changeset.change(
      github_issue_id: github_issue.id,
      github_issue_number: github_issue.number
    )
    |> Ecto.Changeset.unique_constraint(:github_issue_id)
    |> Repo.update()
    |> handle_constraint_error()
  end

  def update_shared_issue(shared_issue, %Ln.Issue{} = linear_issue) do
    shared_issue
    |> Ecto.Changeset.change(
      linear_issue_id: linear_issue.id,
      linear_issue_number: linear_issue.number
    )
    |> Ecto.Changeset.unique_constraint(:linear_issue_id)
    |> Repo.update()
    |> handle_constraint_error()
  end

  @doc """
  """
  def handle_constraint_error({:error, %Ecto.Changeset{}}),
    do: {:error, :invalid_constraint}

  def handle_constraint_error({:ok, _struct} = value), do: value

  @doc """
  """
  def delete_existing_shared_issue(%Gh.Issue{} = github_issue) do
    Repo.delete_all(from s in SharedIssue, where: s.github_issue_id == ^github_issue.id)
    :ok
  end

  def delete_existing_shared_issue(%Ln.Issue{} = linear_issue) do
    Repo.delete_all(from s in SharedIssue, where: s.linear_issue_id == ^linear_issue.id)
    :ok
  end

  defmodule Labels do
    @doc """
    """
    def to_label_mapset(labels) when is_list(labels) do
      labels |> Enum.reject(& &1 == nil) |> Enum.map(& &1.id) |> MapSet.new()
    end

    @doc """
    """
    def get_corresponding_linear_label(%Gh.Label{} = github_label, linear_labels) do
      Enum.find(linear_labels, fn %Ln.Label{} = linear_label ->
        if labels_match?(linear_label.name, github_label.name), do: linear_label, else: nil
      end)
    end

    @doc """
    """
    def get_updated_linear_labels(%{
      "data" => %{"labelIds" => current_label_ids},
      "updatedFrom" => %{"labelIds" => prev_label_ids}
    }) do
      %{
        added_label_ids: current_label_ids -- prev_label_ids,
        removed_label_ids: prev_label_ids -- current_label_ids
      }
    end

    @doc """
    Checks if two labels are equal, uses a case-insensitive comparison.
    """
    def labels_match?(label_a, label_b) do
      String.downcase(label_a) == String.downcase(label_b)
    end
  end
end
