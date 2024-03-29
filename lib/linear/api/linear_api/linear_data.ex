defmodule Linear.LinearAPI.LinearData do
  alias __MODULE__

  defmodule Issue do
    @enforce_keys [:id, :team_id, :title, :description, :number, :url, :team]
    defstruct [:id, :team_id, :title, :description, :number, :url, :team, :labels]

    def new(attrs) do
      LinearData.new(__MODULE__, attrs)
      |> Map.update!(:team, &LinearData.Team.new/1)
      |> Map.update!(:labels, &LinearData.Label.new_list/1)
    end
  end

  defmodule Comment do
    @enforce_keys [:id, :body]
    defstruct [:id, :body]

    def new(attrs) do
      LinearData.new(__MODULE__, attrs)
    end
  end

  defmodule Team do
    @enforce_keys [:id, :key]
    defstruct [:id, :key]

    def new(attrs) do
      LinearData.new(__MODULE__, attrs)
    end
  end

  defmodule Label do
    @enforce_keys [:id, :name]
    defstruct [:id, :name]

    def new(attrs) do
      LinearData.new(__MODULE__, attrs)
    end

    def new_list(%{"nodes" => labels}) do
      Enum.map(labels, &LinearData.new(__MODULE__, &1))
    end

    def new_list(_otherwise), do: nil
  end

  def new(struct_module, attrs) do
    fields =
      struct_module.__struct__()
      |> Map.keys()
      |> Enum.map(fn key -> {key, attrs[Inflex.camelize(key, :lower)]} end)

    struct(struct_module, fields)
  end
end
