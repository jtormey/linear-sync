defmodule Linear.Actions.UpdateGithubIssue do
  require Logger

  alias Linear.Actions.Helpers
  alias Linear.Util

  @enforce_keys []
  defstruct [:title, :state]

  def new(fields), do: struct(__MODULE__, fields)

  def requires?(dep), do: dep == :github

  def process(%__MODULE__{} = action, %{issue_sync: issue_sync} = context) do
    {client, repo_key} = Helpers.client_repo_key(issue_sync)

    params =
      %{}
      |> Util.Control.put_non_nil("title", action.title)
      |> Util.Control.put_non_nil("state", action.state, &Atom.to_string/1)

    Helpers.github_api().update_issue(
      client,
      repo_key,
      context.shared_issue.github_issue_number,
      params
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
