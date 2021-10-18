defmodule Linear.Actions.CreateLinearComment do
  alias Linear.LinearAPI
  alias Linear.LinearQuery

  @enforce_keys [:body]
  defstruct [:body]

  def new(fields), do: struct(__MODULE__, fields)

  def requires?(dep), do: dep == :linear

  def process(%__MODULE__{} = action, %{issue_sync: issue_sync} = context) do
    session = LinearAPI.Session.new(issue_sync.account)

    LinearQuery.create_issue_comment(
      session,
      context.shared_issue.linear_issue_id,
      body: action.body
    ) |> case do
      {:ok, _linear_comment_data} ->
        {:ok, context}

      :error ->
        {:error, :create_linear_comment}
    end
  end
end
