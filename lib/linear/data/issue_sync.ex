defmodule Linear.Data.IssueSync do
  use Ecto.Schema
  import Ecto.Changeset

  alias Linear.Accounts.Account
  alias Linear.Data.LnIssue

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "issue_syncs" do
    field :dest_name, :string
    field :enabled, :boolean, default: false
    field :external_id, :string
    field :label_id, :binary_id
    field :repo_id, :integer
    field :repo_owner, :string
    field :repo_name, :string
    field :assignee_id, :binary_id
    field :source_name, :string
    field :open_state_id, :binary_id
    field :close_state_id, :binary_id
    field :team_id, :binary_id
    field :linear_webhook_id, :binary_id
    field :github_webhook_id, :integer
    field :close_on_open, :boolean, default: false

    belongs_to :account, Account
    has_many :ln_issues, LnIssue

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(issue_sync, attrs) do
    issue_sync
    |> cast(attrs, [:source_name, :dest_name, :enabled, :repo_id, :repo_owner, :repo_name, :team_id, :open_state_id, :close_state_id, :label_id, :assignee_id, :linear_webhook_id, :github_webhook_id, :close_on_open])
    |> validate_required([:source_name, :dest_name, :enabled, :repo_id, :repo_owner, :repo_name, :team_id])
    |> unique_constraint(:repo_id, name: :issue_syncs_team_id_repo_id_index, message: "there is already an issue sync for this team repo combination")
  end

  @doc false
  def assoc_changeset(issue_sync, account = %Account{}, attrs) do
    issue_sync
    |> changeset(attrs)
    |> put_change(:external_id, generate_external_id())
    |> put_assoc(:account, account)
  end

  def generate_external_id() do
    Ecto.UUID.generate()
    |> String.split("-")
    |> List.last()
  end
end
