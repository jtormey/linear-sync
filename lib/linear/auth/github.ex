defmodule Linear.Auth.Github do
  use OAuth2.Strategy

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

  def authorize_url!(state) do
    scope = fetch_env!(:scope)
    OAuth2.Client.authorize_url!(client(), scope: format_scope(scope), state: state)
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

  def fetch_env!(key) do
    Application.fetch_env!(:linear, __MODULE__)[key]
  end

  def format_scope(nil), do: ""
  def format_scope(scope) when is_binary(scope), do: scope
  def format_scope(scope) when is_list(scope), do: Enum.join(scope, ",")
end
