defmodule Linear.Actions.FetchLinearIssue do
  alias Linear.Actions.Helpers
  alias Linear.LinearAPI
  alias Linear.LinearQuery
  alias Linear.LinearAPI.LinearData, as: Ln

  @enforce_keys []
  defstruct [:issue_number]

  def new(fields \\ %{}), do: struct(__MODULE__, fields)

  def process(%__MODULE__{} = action, %{issue_sync: issue_sync} = context) do
    with nil <- action.issue_number,
         nil <- context.shared_issue.linear_issue_number do
      {:error, :missing_issue_number}
    else
      issue_number when is_integer(issue_number) ->
        session = LinearAPI.Session.new(issue_sync.account)

        case LinearQuery.get_issue_by_id(session, issue_number) do
          {:ok, linear_issue_data} ->
            linear_issue = Ln.Issue.new(linear_issue_data)

            context =
              context
              |> Map.update!(
                :shared_issue,
                &Helpers.update_shared_issue!(&1, linear_issue)
              )
              |> Map.put(:linear_issue, linear_issue)

            {:ok, context}

          :error ->
            {:error, :fetch_linear_issue}
        end
    end
  end
end
