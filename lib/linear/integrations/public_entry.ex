defmodule Linear.Integrations.PublicEntry do
  use Ecto.Schema
  import Ecto.Changeset

  alias Linear.Accounts.Account

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "public_entries" do
    field :name, :string
    field :external_id, :string
    field :enabled, :boolean, default: true
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
    |> put_change(:external_id, generate_external_id())
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

defimpl Phoenix.Param, for: Linear.Integrations.PublicEntry do
  @impl true
  def to_param(public_entry) do
    Linear.Integrations.PublicEntry.to_param(public_entry)
  end
end
