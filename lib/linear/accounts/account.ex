defmodule Linear.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  alias Linear.LinearAPI

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "accounts" do
    field :api_key, :string
    field :github_token, :string
    field :github_link_state, :string

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:api_key])
    |> validate_required([:api_key])
    |> validate_linear_api_key(:api_key)
    |> unique_constraint(:api_key, name: :accounts_api_key_index)
  end

  def validate_linear_api_key(changeset, field) do
    validate_change changeset, field, fn ^field, value ->
      value
      |> LinearAPI.Session.new()
      |> LinearAPI.viewer()
      |> case do
        {:ok, %{"data" => %{"viewer" => _viewer}}} ->
          []

        _otherwise ->
          [{field, "unable to authenticate Linear api key"}]
      end
    end
  end
end
