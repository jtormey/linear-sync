defmodule Linear.Integrations.PublicEntry do
  use Ecto.Schema
  import Ecto.Changeset

  alias Linear.Accounts.Account

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "public_entries" do
    field :name, :string
    field :assign_self, :boolean, default: false
    field :label_id, :binary_id
    field :project_id, :binary_id
    field :state_id, :binary_id
    field :team_id, :binary_id

    belongs_to :account, Account

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(public_entry, account = %Account{}, attrs) do
    public_entry
    |> cast(attrs, [:name, :team_id, :label_id, :state_id, :project_id, :assign_self])
    |> validate_required([:name, :team_id, :assign_self])
    |> put_assoc(:account, account)
  end
end
