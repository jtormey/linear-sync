defmodule Linear.Actions.CreateGithubComment do
  require Logger

  alias Linear.Actions.Helpers

  @enforce_keys []
  defstruct [:body, :create_body]

  def new(fields), do: struct(__MODULE__, fields)

  def requires?(dep), do: dep == :github

  def process(%__MODULE__{} = action, %{issue_sync: issue_sync} = context) do
    {client, repo_key} = Helpers.client_repo_key(issue_sync)

    Helpers.github_api().create_issue_comment(
      client,
      repo_key,
      context.shared_issue.github_issue_number,
      action.body || action.create_body.(context)
    )
    |> case do
      {201, _body, _response} ->
        {:ok, context}

      error ->
        Logger.error("Error creating github issue comment: #{inspect(error)}")

        {:error, :create_github_comment}
    end
  end
end
