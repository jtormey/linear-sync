defmodule Linear.LinearAPI.Behaviour do
  alias Linear.LinearAPI.Session

  @callback new_issue_sync_data(Session.t(), String.t()) :: {:ok, map()} | {:error, map()}

  @callback viewer(Session.t()) :: {:ok, map()} | {:error, map()}

  @callback organization(Session.t()) :: {:ok, map()} | {:error, map()}

  @callback teams(Session.t()) :: {:ok, map()} | {:error, map()}

  @callback viewer_teams(Session.t()) :: {:ok, map()} | {:error, map()}

  @callback issue(Session.t(), String.t()) :: {:ok, map()} | {:error, map()}

  @callback create_issue(Session.t(), Keyword.t()) :: {:ok, map()} | {:error, map()}

  @callback create_comment(Session.t(), Keyword.t()) :: {:ok, map()} | {:error, map()}

  @callback update_issue(Session.t(), Keyword.t()) :: {:ok, map()} | {:error, map()}

  @callback create_webhook(Session.t(), Keyword.t()) :: {:ok, map()} | {:error, map()}

  @callback get_webhooks(Session.t()) :: {:ok, map()} | {:error, map()}

  @callback delete_webhook(Session.t(), Keyword.t()) :: {:ok, map()} | {:error, map()}

  @callback list_issue_labels(Session.t()) :: {:ok, map()} | {:error, map()}
end
