defmodule Linear.LinearAPI do
  @moduledoc """
  Query the Linear GraphQL API.
  """

  use HTTPoison.Base

  require Logger

  alias HTTPoison.Response
  alias GraphqlBuilder.Query
  alias __MODULE__.Session

  @base_url "https://api.linear.app"

  def new_issue_sync_data(session = %Session{}, team_id) do
    query = %Query{
      operation: :team,
      variables: [id: team_id],
      fields: [
        labels: [nodes: [:id, :name, :archivedAt]],
        states: [nodes: [:id, :name, :description, :archivedAt]]
      ]
    }
    graphql session, GraphqlBuilder.query(query)
  end

  def viewer(session = %Session{}) do
    query = %Query{
      operation: :viewer,
      fields: [:id, :name, :email]
    }
    graphql session, GraphqlBuilder.query(query)
  end

  def teams(session = %Session{}) do
    query = %Query{
      operation: :teams,
      fields: [nodes: [:id, :name]]
    }
    graphql session, GraphqlBuilder.query(query)
  end

  def viewer_teams(session = %Session{}) do
    graphql session, """
    query {
      viewer {
        id
        name
        email
      }
      teams {
        nodes {
          id
          name
        }
      }
    }
    """
  end

  def issue(session = %Session{}, issue_id) do
    query = %Query{
      operation: :issue,
      variables: [id: issue_id],
      fields: [:id, :title, :description]
    }
    graphql session, GraphqlBuilder.query(query)
  end

  def create_issue(session = %Session{}, opts) do
    query = """
    mutation($teamId: String!, $title: String!, $description: String!, $stateId: String, $labelIds: [String!], $assigneeId: String) {
      issueCreate(input: {teamId: $teamId, title: $title, description: $description, stateId: $stateId, labelIds: $labelIds, assigneeId: $assigneeId}) {
        success,
        issue {
          id,
          number,
          title,
          description,
          url
        }
      }
    }
    """
    graphql session, query,
      variables: Keyword.take(opts, [:teamId, :title, :description, :stateId, :labelIds, :assigneeId])
  end

  def create_comment(session = %Session{}, opts) do
    query = """
    mutation($issueId: String!, $body: String!) {
      commentCreate(input: {issueId: $issueId, body: $body}) {
        success,
        comment {
          id,
          body
        }
      }
    }
    """
    graphql session, query,
      variables: Keyword.take(opts, [:issueId, :body])
  end

  def update_issue(session = %Session{}, opts) do
    query = """
    mutation($issueId: String!, $title: String, $description: String, $stateId: String, $labelIds: [String!], $assigneeId: String) {
      issueUpdate(id: $issueId, input: {title: $title, description: $description, stateId: $stateId, labelIds: $labelIds, assigneeId: $assigneeId}) {
        success,
        issue {
          id,
          number,
          title,
          description,
          url
        }
      }
    }
    """
    graphql session, query,
      variables: Keyword.take(opts, [:issueId, :title, :description, :stateId, :labelIds, :assigneeId])
  end

  def create_webhook(session = %Session{}, opts) do
    resourceTypes = [resourceTypes: ["Comment","Issue"]]
    opts = Keyword.merge(opts, resourceTypes)
    query = %Query{
      operation: :webhookCreate,
      variables: [input: Keyword.take(opts, [:url, :teamId, :resourceTypes])],
      fields: [:success, webhook: [:id, :enabled]]
    }
    graphql session, GraphqlBuilder.mutation(query)
  end

  def get_webhooks(session = %Session{}) do
    graphql session, """
      query {
        teams {
          nodes {
            webhooks {
              nodes {
                id
                url
                enabled
                creator {
                  name
                }
              }
            }
          }
        }
      }
      """
  end

  def delete_webhook(session = %Session{}, opts) do
    query = %Query{
      operation: :webhookDelete,
      variables: Keyword.take(opts, [:id]),
      fields: [:success]
    }
    graphql session, GraphqlBuilder.mutation(query)
  end

  defp graphql(session = %Session{}, query, opts \\ []) when is_binary(query) do
    variables = Keyword.get(opts, :variables, []) |> Map.new()

    Logger.debug("Running graphql query #{query} with variables #{inspect variables}")

    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", session.api_key}
    ]

    "/graphql"
    |> post(Jason.encode!(%{query: query, variables: variables}), headers)
    |> handle_response()
  end

  def handle_response({:ok, %Response{status_code: 200, body: body}}), do: {:ok, body}
  def handle_response({:ok, %Response{status_code: _, body: body}}), do: {:error, body}

  @impl true
  def process_request_url(url), do: @base_url <> url

  @impl true
  def process_response_body(body), do: Jason.decode!(body)
end
