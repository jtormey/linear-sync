defmodule Linear.Actions.BlockLinearPrivateIssue do
  alias Linear.Actions.Helpers
  alias Linear.LinearAPI
  alias Linear.LinearQuery
  alias Linear.LinearAPI.LinearData, as: Ln

  @enforce_keys []
  defstruct []

  @private_label "private"

  def new(fields \\ %{}), do: struct(__MODULE__, fields)

  def process(%__MODULE__{}, context) do
    case fetch_labels(context) do
      {:ok, labels} ->
        if has_private_label?(labels) do
          {:error, :linear_issue_is_private}
        else
          {:ok, context}
        end

      :error ->
        {:error, :block_linear_private_issue}
    end
  end

  defp fetch_labels(context) do
    with :error <- fetch_labels_from_context(context),
         :error <- fetch_labels_from_linear_query(context) do
      :error
    end
  end

  defp fetch_labels_from_context(context) do
    if labels = context.linear_issue.labels, do: {:ok, labels}, else: :error
  end

  defp fetch_labels_from_linear_query(%{issue_sync: issue_sync} = context) do
    session = LinearAPI.Session.new(issue_sync.account)

    with {:ok, labels} <- LinearQuery.list_issue_labels(session, context.linear_issue.id) do
      {:ok, Enum.map(labels, &Ln.Label.new/1)}
    end
  end

  defp has_private_label?(labels) do
    Enum.any?(labels, &Helpers.Labels.labels_match?(&1.name, @private_label))
  end
end
