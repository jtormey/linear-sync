defmodule Linear.LinearAPI.Session do
  @moduledoc """
  Represents a Linear GraphQL API session.
  """

  alias Linear.Accounts.Account

  @enforce_keys [:api_key]
  defstruct [:api_key]

  def new(), do: Application.fetch_env!(:linear, Linear.LinearAPI)[:api_key] |> new()

  def new(account = %Account{}), do: new(account.api_key)

  def new(api_key) when is_binary(api_key), do: %__MODULE__{api_key: api_key}
end
