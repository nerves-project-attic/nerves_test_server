defmodule NervesTestServer.Scheduler do
  use GenServer

  alias NervesTestServer.Test
  alias NervesTestServer.Test.Context

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def schedule_tests(%Context{} = context) do
    GenServer.call(__MODULE__, {:schedule_tests, context})
  end

  def scheduled_tests(tag) do
    GenServer.call(__MODULE__, {:scheduled_tests, tag})
  end

  def cancel_test(tag, test) do
    GenServer.call(__MODULE__, {:cancel_test, tag, test})
  end

  def init(_opts) do
    Process.flag(:trap_exit, true)
    {:ok, %{
      tests: %{},
      devices: %{}
    }}
  end

  def handle_call({:schedule_tests, %Context{tags: tags} = ctx}, _from, s) do
    resp = Enum.reduce(tags, %{}, & Map.put(&2, &1, []))
    {resp, tests} =
      Enum.reduce(tags, {resp, s.tests}, fn(tag, {resp, tests}) ->
        {:ok, test} =
          Map.put(ctx, :tag, tag)
          |> Test.start_link()

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
      List.first(test)
      |> Test.stop()
    end

    {:reply, tests, %{s | tests: Map.put(s.tests, tag, :queue.from_list(tests))}}
  end

  def handle_info({:EXIT, _pid, :normal}, s) do
    {:noreply, s}
  end
end
