defmodule Foo do
  defmacro bar(pid) do
    quote do
      defmodule Baz do
        def x, do: unquote(pid)
      end
    end
  end
end
