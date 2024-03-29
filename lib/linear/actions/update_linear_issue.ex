defmodule Linear.Actions.UpdateLinearIssue do
  alias Linear.LinearAPI
  alias Linear.LinearQuery
  alias Linear.Actions.Helpers
  alias Linear.Util

  @enforce_keys []
  defstruct [:state_id, add_labels: [], remove_labels: []]

  def new(fields), do: struct(__MODULE__, fields)

  def requires?(dep), do: dep == :linear

  def process(%__MODULE__{} = action, %{issue_sync: issue_sync} = context) do
    session = LinearAPI.Session.new(issue_sync.account)

    args = update_issue_args(action, context)

    case LinearQuery.update_issue(session, context.shared_issue.linear_issue_id, args) do
      :ok ->
        {:ok, context}

      :error ->
        {:error, :update_linear_issue}
    end
  end

  defp update_issue_args(%__MODULE__{state_id: nil} = action, context) do
    labels_to_add =
      action.add_labels
      |> Enum.map(&Helpers.Labels.get_corresponding_linear_label(&1, context.linear_labels))
      |> Helpers.Labels.to_label_mapset()

    labels_to_remove =
      action.remove_labels
      |> Enum.map(&Helpers.Labels.get_corresponding_linear_label(&1, context.linear_labels))
      |> Helpers.Labels.to_label_mapset()

    current_label_ids = Helpers.Labels.to_label_mapset(context.linear_issue.labels)

    updated_label_ids =
      current_label_ids
      |> MapSet.union(labels_to_add)
      |> MapSet.difference(labels_to_remove)

    labels_changed? = updated_label_ids != current_label_ids

    Util.Control.put_if([], :labelIds, MapSet.to_list(updated_label_ids), labels_changed?)
  end

  defp update_issue_args(%__MODULE__{} = action, _context) do
    Util.Control.put_non_nil([], :stateId, action.state_id)
  end
end
