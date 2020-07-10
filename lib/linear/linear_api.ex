defmodule Linear.LinearAPI do
  @moduledoc """
  Query the Linear GraphQL API.
  """

  use HTTPoison.Base

  alias HTTPoison.Response
  alias __MODULE__.Session

  @base_url "https://api.linear.app"

  def new_public_entry_data(session = %Session{}, team_id) do
    graphql session, """
    query {
      team(id: "#{team_id}") {
        labels {
          nodes {
            id
            name
            archivedAt
          }
        }
        states {
          nodes {
            id
            name
            description
            archivedAt
          }
        }
        projects {
          nodes {
            id
            name
            color
            archivedAt
            completedAt
          }
        }
      }
    }
    """
  end

  def viewer(session = %Session{}) do
    graphql session, """
    query {
      viewer {
        id
        name
        email
      }
    }
    """
  end

  def teams(session = %Session{}) do
    graphql session, """
    query {
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
    graphql session, """
    query {
      issue(id: "#{issue_id}") {
        id
        title
        description
      }
    }
    """
  end

  def create_issue(session = %Session{}, team_id, title, description) do
    graphql session, """
    mutation {
      issueCreate(input: { title: "#{title}", description: "#{description}", teamId: "#{team_id}" }) {
        success
        issue {
          id
          title
          description
        }
      }
    }
    """
  end

  def update_issue(session = %Session{}, issue_id, title, description) do
    graphql session, """
    mutation {
      issueUpdate(id: "#{issue_id}", input: { title: "#{title}", description: "#{description}" }) {
        success
        issue {
          id
          title
          description
        }
      }
    }
    """
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
