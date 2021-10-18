defmodule Linear.Actions.FetchLinearIssue do
  alias Linear.Actions.Helpers
  alias Linear.LinearAPI
  alias Linear.LinearQuery
  alias Linear.LinearAPI.LinearData, as: Ln

  @enforce_keys []
  defstruct [:issue_id, :issue_key, replace_shared_issue: false]

  def new(fields \\ %{}), do: struct(__MODULE__, fields)

  def requires?(_any), do: false

  def process(%__MODULE__{} = action, %{issue_sync: issue_sync} = context) do
    with nil <- action.issue_id,
         nil <- action.issue_key,
         nil <- context.shared_issue.linear_issue_id,
         nil <- context.linear_issue.id do
      {:error, :missing_issue_key}
    else
      issue_key when is_binary(issue_key) ->
        session = LinearAPI.Session.new(issue_sync.account)

        case LinearQuery.get_issue_by_id(session, issue_key) do
          {:ok, linear_issue_data} ->
            linear_issue = Ln.Issue.new(linear_issue_data)

            if action.replace_shared_issue do
              :ok = Helpers.delete_existing_shared_issue(linear_issue)
            end

            context.shared_issue
            |> Helpers.update_shared_issue(linear_issue)
            |> case do
              {:ok, shared_issue} ->
                context =
                  context
                  |> Map.put(:shared_issue, shared_issue)
                  |> Map.put(:linear_issue, linear_issue)

                {:ok, context}

              {:error, reason} ->
                {:error, {:fetch_linear_issue, reason}}
            end

          :error ->
            {:error, :fetch_linear_issue}
        end
    end
  end
end
