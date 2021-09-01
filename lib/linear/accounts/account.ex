defmodule Linear.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  alias Linear.Data.IssueSync

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "accounts" do
    field :api_key, :string
    field :organization_id, Ecto.UUID
    field :github_token, :string
    field :github_link_state, :string

    has_many :issue_syncs, IssueSync

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
