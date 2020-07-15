defmodule Linear.LinearAPI do
  @moduledoc """
  Query the Linear GraphQL API.
  """

  use HTTPoison.Base

  alias HTTPoison.Response
  alias GraphqlBuilder.Query
  alias __MODULE__.Session

  @base_url "https://api.linear.app"

  def new_public_entry_data(session = %Session{}, team_id) do
    query = %Query{
      operation: :team,
      variables: [id: team_id],
      fields: [
        labels: [nodes: [:id, :name, :archivedAt]],
        states: [nodes: [:id, :name, :description, :archivedAt]],
        projects: [nodes: [:id, :name, :color, :archivedAt, :completedAt]],
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

  def create_issue(session = %Session{}, team_id, title, description) do
    query = %Query{
      operation: :issueCreate,
      variables: [input: [teamId: team_id, title: title, description: description]],
      fields: [
        :success,
        issue: [:id, :number, :title, :description, :url]
      ]
    }
    graphql session, GraphqlBuilder.mutation(query)
  end

  def update_issue(session = %Session{}, issue_id, title, description) do
    query = %Query{
      operation: :issueUpdate,
      variables: [id: issue_id, input: [title: title, description: description]],
      fields: [
        :success,
        issue: [:id, :number, :title, :description, :url]
      ]
    }
    graphql session, GraphqlBuilder.mutation(query)
  end

  defp graphql(session = %Session{}, query) when is_binary(query) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", session.api_key}
    ]
    "/graphql"
    |> post(Jason.encode!(%{query: query}), headers)
    |> handle_response()
  end

  def handle_response({:ok, %Response{status_code: 200, body: body}}), do: {:ok, body}
  def handle_response({:ok, %Response{status_code: _, body: body}}), do: {:error, body}

  @impl true
  def process_request_url(url), do: @base_url <> url

  @impl true
  def process_response_body(body), do: Jason.decode!(body)
end
