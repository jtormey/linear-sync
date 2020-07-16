defmodule Linear.Data.IssueSync do
  use Ecto.Schema
  import Ecto.Changeset

  alias Linear.Accounts.Account

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "issue_syncs" do
    field :dest_name, :string
    field :enabled, :boolean, default: false
    field :external_id, :string
    field :label_id, :binary_id
    field :project_id, :binary_id
    field :repo_id, :string
    field :self_assign, :boolean, default: false
    field :source_name, :string
    field :state_id, :binary_id
    field :team_id, :binary_id

    belongs_to :account, Account

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(issue_sync, attrs) do
    issue_sync
    |> cast(attrs, [:source_name, :dest_name, :enabled, :repo_id, :team_id, :state_id, :label_id, :project_id, :self_assign])
    |> validate_required([:source_name, :dest_name, :enabled, :repo_id, :team_id, :self_assign])
    |> put_change(:external_id, generate_external_id())
  end

  @doc false
  def assoc_changeset(issue_sync, account = %Account{}, attrs) do
    issue_sync
    |> changeset(attrs)
    |> put_assoc(:account, account)
  end

  def generate_external_id() do
    Ecto.UUID.generate()
    |> String.split("-")
    |> List.last()
  end

  def to_param(public_entry = %__MODULE__{}) do
    public_entry.name
    |> String.downcase()
    |> String.split(" ")
    |> Enum.join("-")
    |> Kernel.<>("-")
    |> Kernel.<>(public_entry.external_id)
  end

  def from_param(param) when is_binary(param) do
    param
    |> String.split("-")
    |> List.last()
  end
end

defimpl Phoenix.Param, for: Linear.Data.IssueSync do
  @impl true
  def to_param(public_entry) do
    Linear.Data.IssueSync.to_param(public_entry)
  end
end
