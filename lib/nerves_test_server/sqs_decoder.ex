defmodule NervesTestServer.SQSDecoder do
  use GenStage

  def start_link(opts \\ []) do
    GenStage.start_link(__MODULE__, nil, opts)
  end

  def init(nil) do
    {:producer_consumer, nil, subscribe_to: [{:sqs_producer, max_demand: 10}]}
  end

  def handle_events(events, _from, s) do
    events =
      Enum.map(events, & Map.put(&1, :body, Poison.decode!(&1.body)))
    {:noreply, events, s}
  end
end
