defmodule Linear.Webhooks.GithubWebhook do
  use Ecto.Schema
  import Ecto.Changeset

  alias Linear.Accounts.Account
  alias Linear.Data.IssueSync

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "github_webhooks" do
    field :repo_id, :integer
    field :repo_owner, :string
    field :repo_name, :string
    field :webhook_id, :integer

    belongs_to :account, Account
    has_many :issue_syncs, IssueSync, foreign_key: :github_internal_webhook_id

    timestamps()
  end

  @doc false
  def create_changeset(github_webhook, %Account{} = account, attrs) do
    github_webhook
    |> cast(attrs, [:repo_id, :repo_owner, :repo_name])
    |> validate_required([:repo_id, :repo_owner, :repo_name])
    |> put_assoc(:account, account)
    |> unique_constraint([:repo_id])
    |> unique_constraint([:repo_owner, :repo_name])
  end

  @doc false
  def update_changeset(github_webhook, attrs) do
    github_webhook
    |> cast(attrs, [:webhook_id])
    |> validate_required([:webhook_id])
  end
end
