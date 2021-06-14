defmodule Linear.GithubAPI.GithubData do
  alias __MODULE__

  defmodule __MODULE__.Repo do
    @enforce_keys [:id]
    defstruct [:id]

    def new(attrs), do: GithubData.new(__MODULE__, attrs)
  end

  defmodule __MODULE__.Issue do
    @enforce_keys [:id, :title, :body, :number, :user, :html_url]
    defstruct [:id, :title, :body, :number, :user, :html_url]

    def new(attrs) do
      GithubData.new(__MODULE__, attrs)
      |> Map.update!(:user, &GithubData.User.new/1)
    end
  end

  defmodule __MODULE__.Comment do
    @enforce_keys [:id, :body, :user, :html_url]
    defstruct [:id, :body, :user, :html_url]

    def new(attrs) do
      GithubData.new(__MODULE__, attrs)
      |> Map.update!(:user, &GithubData.User.new/1)
    end
  end

  defmodule __MODULE__.User do
    @enforce_keys [:id, :login, :html_url]
    defstruct [:id, :login, :html_url]

    def new(attrs), do: GithubData.new(__MODULE__, attrs)
  end

  def new(struct_module, attrs) do
    fields =
      struct_module.__struct__()
      |> Map.keys()
      |> Enum.map(fn key -> {key, attrs[to_string(key)]} end)

    struct(struct_module, fields)
  end
end
