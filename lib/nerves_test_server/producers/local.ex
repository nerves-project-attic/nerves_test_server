defmodule NervesTestServer.Producers.Local do
  use NervesTestServer.Producer

  def start_link(opts \\ []) do
    Logger.debug "Start Local Producer"
    GenStage.start_link(__MODULE__, opts, [name: __MODULE__])
  end

  def ack(nil), do: :ok
  def ack(message) do
    GenStage.call(__MODULE__, {:ack, message})
  end

  def init(_opts) do
    state = %{
      demand: 0
    }

    {:producer, state, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_demand(incoming_demand, state) do
    new_demand = state.demand + incoming_demand
    {:noreply, [], %{state| demand: new_demand}}
  end

  def handle_call({:ack, _message}, _from, state) do
    {:reply, :ok, [], state}
  end
end
