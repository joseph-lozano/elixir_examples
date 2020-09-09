defmodule Example.ServerTest do
  @doc "Black magic metaprogamming. Almost certainly a mistake, and not best practice"

  alias Example.Server
  use ExUnit.Case

  @valid_interval :timer.seconds(5)
  @invalid_interval :timer.seconds(5) |> to_string()

  @valid_name :valid_name
  @invalid_name "invalid_name"

  defmacro get_api(test) do
    quote do
      defmodule :"Elxir.TestAPI#{unquote(test)}" do
        @ok_pid Agent.start(fn -> 0 end)
        def get(),
          do: Agent.get_and_update(elem(@ok_pid, 1), fn x -> {{:ok, %{value: x}}, x + 1} end)
      end
    end
  end

  setup tags do
    test =
      tags[:test]
      |> Atom.to_string()
      |> String.capitalize()
      |> String.replace(~r{\s+}, "")

    {:module, api, _, _} = get_api(test)
    %{api: api}
  end

  describe "start_link" do
    test "interval must be provided as an integer", %{api: api} do
      # use start_supervised to ensure that the genserver lives and dies with the test
      assert {:error, {:must_provide_interval, _}} = start_supervised({Server, []})

      assert {:error, {:interval_must_be_integer, _}} =
               start_supervised({Server, interval: @invalid_interval})

      assert {:ok, pid} = start_supervised({Server, interval: @valid_interval, api: api})
      assert is_pid(pid)
    end

    test "a name can be provided", %{api: api} do
      assert {:error, {:name_must_be_atom, _}} =
               start_supervised({Server, interval: @valid_interval, name: @invalid_name})

      assert {:ok, pid} =
               start_supervised({Server, interval: @valid_interval, name: @valid_name, api: api})

      pid = Process.whereis(@valid_name)
      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "module must be provided" do
      assert {:error, {:must_provide_api, _}} =
               start_supervised({Server, interval: @valid_interval})

      assert {:error, {:api_must_be_module, _}} =
               start_supervised({Server, interval: @valid_interval, api: "A"})
    end

    test "initial api call is made", %{api: api} do
      assert {:ok, pid} = start_supervised({Server, interval: @valid_interval, api: api})
      %{value: 0} = Server.get_state(pid)
    end

    test "api call is made at least every interval", %{api: api} do
      # shorter inverval to keep the test from taking long
      interval = 50
      wait = 5
      assert {:ok, pid} = start_supervised({Server, interval: interval, api: api})
      :timer.sleep(interval * wait)
      %{value: v} = Server.get_state(pid)
      assert v == wait - 1
    end
  end
end
