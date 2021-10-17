defmodule Linear.Util do
  defmodule Control do
    def put_if(opts, key, val, condition),
      do: if(condition, do: put_keymap(opts, key, val), else: opts)

    def put_non_nil(opts, key, val, process \\ & &1)
    def put_non_nil(opts, _key, nil, _process), do: opts
    def put_non_nil(opts, key, val, process), do: put_keymap(opts, key, process.(val))

    def put_keymap(opts, key, val) when is_list(opts), do: Keyword.put(opts, key, val)
    def put_keymap(opts, key, val) when is_map(opts), do: Map.put(opts, key, val)
  end
end
