defmodule NervesTestServer.Device do
  use GenStage

  require Logger
  alias ExAws.SQS

  def start_link(target, queue_name, producers, opts \\ []) do
    GenStage.start_link(__MODULE__, [target: target, queue: queue_name, producers: producers], opts)
  end

  def init(opts) do
    queue = opts[:queue]
    producers = opts[:producers]
    target = opts[:target]
    topic = opts[:topic]

    state = %{
      queue: queue,
      target: target,
      topic: topic
    }

    subscriptions = Enum.map(producers, &({&1, [
      max_demand: 1,
      selector: fn(message) ->
        body =
          message
          |> Map.get(:body)
          |> Poison.decode!
        records =
          Map.get(body, "Records")
        Enum.any?(records, fn(record) ->
          get_in(record, ["s3", "object", "key"])
          |> IO.inspect
          |> String.starts_with?("fw/#{target}")
          |> IO.inspect
        end)
      end
    ]}))
    {:consumer, state, subscribe_to: subscriptions}
  end

  def handle_events(messages, _from, state) do
    handle_messages(messages, state)
    {:noreply, [], state}
  end

  defp handle_messages(messages, state) do
    ## You probably want to handle errors or issues by NOT deleting
    ## those messages, but this is fine for our example
    Enum.each(messages, &process_message/1)

    state.queue
    |> SQS.delete_message_batch(Enum.map(messages, &make_batch_item/1))
    |> ExAws.request
  end

  defp make_batch_item(message) do
    %{id: Map.get(message, :message_id), receipt_handle: Map.get(message, :receipt_handle)}
  end

  defp process_message(message) do
    ## Do something to process message here
    #Logger.debug "Received Message: #{inspect message}"
    body =
      message
      |> Map.get(:body)
      |> Poison.decode!
    records =
      Map.get(body, "Records")
    Enum.each(records, fn(record) ->
      case get_in(record, ["s3", "object", "key"]) do
        nil -> :noop
        key ->
          IO.inspect key, label: "Key"
      end
    end)
    {:ok, message}
  end

end
