defmodule NervesTestServer.Device do
  use GenStage

  require Logger
  alias ExAws.SQS
  alias NervesTestServer.Web.Endpoint
  alias NervesTestServer.{Repo, Build}

  @queue "nerves-test-server"
  @prefix "test_server"
  @org "nerves-project"
  @producers [NervesTestServer.SQSProducer]
  @timeout 60_000 * 9 # 9 minutes

  def start_link(device, system, topic, opts \\ []) do
    GenStage.start_link(__MODULE__, {device, system, topic, self()}, opts) |> IO.inspect
  end

  def result(pid, result) do
    GenStage.call(pid, {:result, result})
  end

  def init({device, system, topic, socket}) do
    producers = @producers
    state = %{
      device: device,
      queue: @queue,
      system: system,
      topic: topic,
      message: nil,
      key: "#{@prefix}/#{@org}/#{system}",
      timeout_t: nil
    }

    subscriptions = Enum.map(producers, &({&1, [
      max_demand: 1,
      selector: fn(%{key: key}) ->
        String.starts_with?(key, state.key)
      end
    ]}))
    {:consumer, state, subscribe_to: subscriptions}
  end

  def handle_call({:result, result}, _from, s) do
    # TODO: Persist the results to the DB
    if t = s.timeout_t do
      Process.cancel_timer(t)
    end

    Logger.debug "Device Received Results: #{inspect result}"
    Logger.debug "Message: #{inspect s.message}"
    {:reply, :ok, [], delete_message(s)}
  end

  def handle_info(:timeout, s) do
    Logger.debug "Timeout Expired"
    {:noreply, [], s}
  end

  def handle_events([message], _from, s) do
    {:noreply, [], process_message(message, s)}
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

  defp process_message(message, s) do
    ## Do something to process message here
    Logger.debug "Received Message: #{inspect message}"
    @prefix <> "/" <> key_path = message.key
    [org, system, fw] =
      String.split(key_path, "/", parts: 3)
    vcs_id = Path.rootname(fw)
    # build =
    #   %Build{
    #     org: org,
    #     system: system,
    #     vcs_id: vcs_id
    #   }
    # Repo.insert(build)
    Endpoint.broadcast(s.topic, "apply", %{"fw" => fw_url(org, system, fw)})

    t = Process.send_after(self(), :timeout, @timeout)
    # TODO: Start a timer to wait for the device.
    #  If the timer expires, kill the process.
    #  Ack the message when the timer expires.
    #  Save a record that the fw was bad
    %{s | message: message, timeout_t: t}
  end

  def fw_url(org, system, fw) do
    NervesTestServer.Web.Endpoint.url <> "/#{org}/#{system}/#{fw}"
  end

end
