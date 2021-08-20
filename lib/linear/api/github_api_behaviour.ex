defmodule Linear.GithubAPI.Behaviour do
  alias Tentacat.Client

  @type repo_key :: {String.t(), String.t()}

  @callback viewer(Client.t()) ::
    {:ok, map()} | {:error, map()}

  @callback create_issue(Client.t(), repo_key(), map()) ::
    {:ok, map()} | {:error, map()}

  @callback close_issue(Client.t(), repo_key(), Integer.t()) ::
    {:ok, map()} | {:error, map()}

  @callback update_issue(Client.t(), repo_key(), Integer.t(), map()) ::
    {:ok, map()} | {:error, map()}

  @callback list_repository_labels(Client.t(), repo_key()) ::
    {:ok, map()} | {:error, map()}

  @callback list_issue_labels(Client.t(), repo_key(), Integer.t()) ::
    {:ok, map()} | {:error, map()}

  @callback add_issue_labels(Client.t(), repo_key(), Integer.t(), list()) ::
    {:ok, map()} | {:error, map()}

  @callback remove_issue_labels(Client.t(), repo_key(), Integer.t(), String.t()) ::
    {:ok, map()} | {:error, map()}

  @callback create_issue_comment(Client.t(), repo_key(), Integer.t(), map()) ::
    {:ok, map()} | {:error, map()}

  @callback create_webhook(Client.t(), repo_key(), Keyword.t()) ::
    {:ok, map()} | {:error, map()}

  @callback delete_webhook(Client.t(), repo_key(), Keyword.t()) ::
    {:ok, map()} | {:error, map()}
end
