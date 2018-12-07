defmodule NervesTestServer.Scheduler do
  use GenServer

  alias NervesTestServer.{Test, Device, Test.Context}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def schedule_tests(context) do
    context = Context.parse(context)
    GenServer.call(__MODULE__, {:schedule_tests, context})
  end

  def scheduled_tests(tag) do
    GenServer.call(__MODULE__, {:scheduled_tests, tag})
  end

  def cancel_test(tag, test) do
    GenServer.call(__MODULE__, {:cancel_test, tag, test})
  end

  def connect_device(%Device{} = device) do
    GenServer.call(__MODULE__, {:connect_device, device})
  end

  def init(_opts) do
    Process.flag(:trap_exit, true)
    {:ok, %{
      tests: %{},
      devices: []
    }}
  end

  def handle_call({:schedule_tests, %Context{tags: tags} = ctx}, _from, s) do
    resp = Enum.reduce(tags, %{}, & Map.put(&2, &1, []))
    {resp, tests} =
      Enum.reduce(tags, {resp, s.tests}, fn(tag, {resp, tests}) ->
        {:ok, test} = Test.start_link(tag, ctx)

        tag_test_q = Map.get(tests, tag, :queue.new())

        {Map.put(resp, tag, [test | resp[tag]]), Map.put(tests, tag, :queue.in(test, tag_test_q))}
      end)

    {:reply, {:ok, resp}, %{s | tests: tests}}
  end

  def handle_call({:scheduled_tests, tag}, _from, s) do
    tag = Map.get(s.tests, tag, :queue.new()) |> :queue.to_list()
    {:reply, tag, s}
  end

  def handle_call({:cancel_test, tag, test}, _from, s) do
    {test, tests} =
      Map.get(s.tests, tag)
      |> :queue.to_list
      |> Enum.split_with(& &1 == test)

    if test != [] do
      Enum.each(test, &Test.stop/1)
    end

    {:reply, tests, s}
  end

  def handle_call({:connect_device, device}, _from, s) do
    {:reply, :ok, %{s | devices: [device | s.devices]}}
  end

  def handle_info({:EXIT, pid, :normal}, s) do
    s =
      case Enum.find(s.tests, & pid in (elem(&1, 1) |> :queue.to_list())) do
        {tag, tests} ->
          tests =
            :queue.to_list(tests)
            |> Enum.reject(& &1 == pid)
          %{s | tests: Map.put(s.tests, tag, :queue.from_list(tests))}

        _ ->
          s
      end
    {:noreply, s}
  end
end
