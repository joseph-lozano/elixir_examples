defmodule Example.Server do
  @doc "Example Server that makes an API call every 5 minutes"

  use GenServer

  # Public API
  @spec start_link(Keyword.t()) :: {:ok, pid()} | {:error, reason :: term()}

  def start_link(opts) when is_list(opts) do
    with {:ok, opts} <- validate(opts) do
      case Keyword.pop(opts, :name) do
        {nil, opts} -> GenServer.start_link(__MODULE__, opts)
        {name, opts} when is_atom(name) -> GenServer.start_link(__MODULE__, opts, name: name)
      end
    end
  end

  defp validate(opts) do
    cond do
      not Keyword.has_key?(opts, :interval) ->
        {:error, :must_provide_interval}

      not is_integer(Keyword.get(opts, :interval)) ->
        {:error, :interval_must_be_integer}

      # nil counts as an atom, so that will still pass this check
      not is_atom(Keyword.get(opts, :name)) ->
        {:error, :name_must_be_atom}

      is_nil(Keyword.get(opts, :api)) ->
        {:error, :must_provide_api}

      not is_atom(Keyword.get(opts, :api)) ->
        {:error, :api_must_be_module}

      true ->
        {:ok, opts}
    end
  end

  def get_state(pid_or_name) do
    GenServer.call(pid_or_name, :get_state)
  end

  @impl true
  def init(opts) do
    init_state = Enum.into(opts, %{})
    {:ok, init_state, {:continue, :api_call}}
  end

  @impl true
  def handle_continue(:api_call, state) do
    case state.api.get() do
      {:ok, resp} -> {:noreply, Map.merge(state, resp), {:continue, :send_after}}
      {:error, reason} -> {:stop, reason}
    end
  end

  def handle_continue(:send_after, state) do
    # Process.send_after will drift.
    # If you need to make the API call at a certain time, e.g. at the top of the hour,
    # consider using a scheduler like Quantum
    Process.send_after(self(), :make_api_call, state.interval)
    {:noreply, state}
  end

  @impl true
  def handle_info(:make_api_call, state) do
    {:noreply, state, {:continue, :api_call}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
end
