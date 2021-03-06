defmodule Linear.Webhooks.LinearWebhook do
  use Ecto.Schema
  import Ecto.Changeset

  alias Linear.Data.IssueSync

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "linear_webhooks" do
    field :team_id, :string
    field :webhook_id, :string

    has_many :issue_syncs, IssueSync, foreign_key: :linear_internal_webhook_id

    timestamps()
  end

  @doc false
  def create_changeset(linear_webhook, attrs) do
    linear_webhook
    |> cast(attrs, [:team_id])
    |> validate_required([:team_id])
    |> unique_constraint([:team_id])
  end

  @doc false
  def update_changeset(linear_webhook, attrs) do
    linear_webhook
    |> cast(attrs, [:webhook_id])
    |> validate_required([:webhook_id])
  end
end
