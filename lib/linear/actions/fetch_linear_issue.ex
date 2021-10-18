defmodule Linear.Actions.FetchLinearIssue do
  alias Linear.Actions.Helpers
  alias Linear.LinearAPI
  alias Linear.LinearQuery
  alias Linear.LinearAPI.LinearData, as: Ln
  alias Linear.Synchronize.ContentWriter

  @enforce_keys []
  defstruct [:issue_key]

  def new(fields \\ %{}), do: struct(__MODULE__, fields)

  def process(%__MODULE__{} = action, %{issue_sync: issue_sync} = context) do
    with nil <- action.issue_key,
         nil <- ContentWriter.linear_issue_key(context.linear_issue, brackets: false) do
      {:error, :missing_issue_key}
    else
      issue_key when is_binary(issue_key) ->
        session = LinearAPI.Session.new(issue_sync.account)

        case LinearQuery.get_issue_by_id(session, issue_key) do
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
