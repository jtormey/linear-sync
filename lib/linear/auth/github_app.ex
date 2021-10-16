defmodule Linear.Auth.GithubApp do
  use OAuth2.Strategy

  @api_url "https://api.github.com"
  @apps_url "https://github.com/apps"

  def client() do
    OAuth2.Client.new([
      strategy: __MODULE__,
      client_id: fetch_env!(:client_id),
      client_secret: fetch_env!(:client_secret),
      redirect_uri: fetch_env!(:redirect_uri),
      site: "https://api.github.com",
      authorize_url: "https://github.com/login/oauth/authorize",
      token_url: "https://github.com/login/oauth/access_token"
    ])
    |> OAuth2.Client.put_serializer("application/json", Jason)
  end

  def authorize_url!(target_id) do
    query_params = URI.encode_query(%{suggested_target_id: target_id})
    @apps_url <> "/#{fetch_env!(:app_name)}/installations/new/permissions?#{query_params}"
  end

  def get_token!(params \\ [], headers \\ [], opts \\ []) do
    OAuth2.Client.get_token!(client(), params, headers, opts)
  end

  @impl true
  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  @impl true
  def get_token(client, params, headers) do
    client
    |> put_header("accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end

  def delete_app_authorization!(installation_id) when is_binary(installation_id) do
    HTTPoison.delete!(
      @api_url <> "/app/installations/#{installation_id}",
      [
        accept: "application/vnd.github.v3+json",
        authorization: jwt_header()
      ]
    )
  end

  defp jwt_header() do
    claims = %{
      # Issued at time, 60 seconds in the past to allow for clock drift
      "iat" => timestamp(-60),
      # JWT expiration time (10 minute maximum)
      "exp" => timestamp(10 * 60),
      # GitHub App's identifier
      "iss" => fetch_env!(:app_id)
    }

    {:ok, jwt} = Joken.Signer.sign(claims, Joken.Signer.parse_config(:github_app_jwt))

    "Bearer #{jwt}"
  end

  defp timestamp(offset) do
    DateTime.utc_now()
    |> DateTime.add(offset, :second)
    |> DateTime.to_unix()
  end

  def fetch_env!(key) do
    Application.fetch_env!(:linear, __MODULE__)[key]
  end
end
