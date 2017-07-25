defmodule NervesTestServer.Device do
  use GenStage

  require Logger
  alias ExAws.SQS

  @queue "nerves-test-server"
  @producers [NervesTestServer.SQSProducer]

  def start_link(device, target, topic, opts \\ []) do
    Logger.debug "Start Device: #{inspect device}"
    GenStage.start_link(__MODULE__, {device, target, topic, self()}, opts) |> IO.inspect
  end

  def result(pid, result) do
    GenStage.call(pid, {:result, result})
  end

  def init({device, target, topic, socket}) do
    producers = @producers
    Process.unlink(socket)
    state = %{
      device: device,
      queue: @queue,
      target: target,
      topic: topic,
      message: nil
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

  def handle_call({:result, result}, _from, s) do
    # TODO: Persist the results to the DB
    Logger.debug "Device Received Results: #{inspect result}"
    {:reply, :ok, [], delete_message(s)}
  end

  def handle_events(message, _from, s) do
    handle_message(message, s)
    {:noreply, [], %{s | message: message}}
  end

  defp handle_message(message, state) do
    process_message(message)
  end

  defp delete_message(%{message: nil} = s), do: s
  defp delete_message(%{message: message} = s) do
    s.queue
    |> SQS.delete_message_batch(make_batch_item(message))
    |> ExAws.request
    %{s | message: nil}
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
          # TODO: Publish to the device to tell it to load the new fw
          # TODO: Start a timer to wait for the device.
          #  If the timer expires, kill the process.
          #  Ack the message when the timer expires.
          #  Save a record that the fw was bad
      end
    end)
    {:ok, message}
  end

end
