defmodule Linear.Actions.FetchLinearLabels do
  alias Linear.LinearAPI
  alias Linear.LinearQuery
  alias Linear.LinearAPI.LinearData, as: Ln

  @enforce_keys []
  defstruct []

  def new(fields \\ %{}), do: struct(__MODULE__, fields)

  def process(%__MODULE__{}, %{issue_sync: issue_sync} = context) do
    session = LinearAPI.Session.new(issue_sync.account)

    case LinearQuery.list_labels(session) do
      {:ok, issue_labels_data} ->
        context =
          Map.put(
            context,
            :linear_labels,
            Enum.map(issue_labels_data, &Ln.Label.new/1)
          )

        {:ok, context}

      :error ->
        {:error, :fetch_linear_labels}
    end
  end
end
