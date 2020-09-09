defmodule Example.Foo do
  def bar do
    quote do
      defmodule Baz do
      end
    end
  end
end
