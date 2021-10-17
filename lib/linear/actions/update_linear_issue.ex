defmodule Linear.Actions.UpdateLinearIssue do
  alias Linear.LinearAPI
  alias Linear.LinearQuery
  alias Linear.Util

  @enforce_keys []
  defstruct [:state_id, :label_ids]

  def new(fields), do: struct(__MODULE__, fields)

  def process(%__MODULE__{} = action, %{issue_sync: issue_sync} = context) do
    session = LinearAPI.Session.new(issue_sync.account)

    args =
      []
      |> Util.Control.put_non_nil(:stateId, action.state_id)
      |> Util.Control.put_non_nil(:labelIds, action.label_ids)

    LinearQuery.update_issue(
      session,
      context.shared_issue.linear_issue_id,
      args
    ) |> case do
      :ok ->
        {:ok, context}

      :error ->
        {:error, :update_linear_issue}
    end
  end
end
