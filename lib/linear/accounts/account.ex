defmodule Linear.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "accounts" do
    field :api_key, :string
    field :organization_id, Ecto.UUID
    field :github_token, :string
    field :github_link_state, :string

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:api_key])
    |> validate_required([:api_key])
    |> unique_constraint(:api_key, name: :accounts_api_key_index)
  end
end
