defmodule NervesTestServer.Device do
  use GenStage
  require Logger

  import Ecto.Query

  alias ExAws.SQS
  alias NervesTestServer.Web.Endpoint
  alias NervesTestServer.{Repo, Build}

  @queue "nerves-test-server"
  @repo_org "nerves-project"
  @producers [NervesTestServer.SQSProducer]
  @timeout 60_000 * 5 # 5 minutes

  def start_link(device, system, topic, opts \\ []) do
    GenStage.start_link(__MODULE__, {device, system, topic, self()}, opts) |> IO.inspect
  end

  def test_begin(pid) do
    GenStage.call(pid, :test_begin)
  end

  def test_result(pid, result) do
    GenStage.call(pid, {:test_result, result})
  end

  def init({device, system, topic, socket}) do
    producers = @producers
    state = %{
      device: device,
      queue: @queue,
      system: system,
      topic: topic,
      message: nil,
      repo_org: @repo_org,
      repo_name: "nerves_system_" <> system,
      timeout_t: nil,
      build: nil
    }

    subscriptions = Enum.map(producers, &({&1, [
      max_demand: 1,
      selector: fn(%{repo_org: repo_org, repo_name: repo_name}) ->
        String.equivalent?(repo_org, state.repo_org) and
        String.equivalent?(repo_name, state.repo_name)
      end
    ]}))
    {:consumer, state, subscribe_to: subscriptions}
  end

  def handle_call(:test_begin, {from, _ref}, s) do
    Logger.debug "Device Test Beginning"
    Process.unlink(from)
    build =
      Build.changeset(s.build, %{start_time: Ecto.DateTime.utc})
      |> Repo.update!
    {:reply, :ok, [], %{s | build: build}}
  end

  def handle_call({:test_result, result}, _from, s) do
    if t = s.timeout_t do
      Process.cancel_timer(t)
    end
    change = %{
      end_time: Ecto.DateTime.utc,
      result: Map.get(result, "test_results"),
      result_io: Map.get(result, "test_io")
    }
    build =
      Build.changeset(s.build, change)
      |> Repo.update!
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
    [%{id: Map.get(message, :message_id), receipt_handle: Map.get(message, :receipt_handle)}]
  end

  defp process_message(message, s) do
    ## Do something to process message here
    Logger.debug "Received Message: #{inspect message}"
    org = message.repo_org
    system = message.repo_name
    vcs_id = message.vcs_id
    fw_url = message.fw_url
    
    s =
      case fetch_build(vcs_id) do
        nil ->
          build = create_build(org, system, vcs_id, s.device)
          Endpoint.broadcast(s.topic, "apply", %{"fw" => fw_url})
          t = Process.send_after(self(), :timeout, @timeout)
          %{s | timeout_t: t, build: build}
        _build ->
          Logger.warn "Build: #{vcs_id} already exists"
          delete_message(s)
      end

    %{s | message: message}
  end

  def fw_url(org, system, fw) do
    NervesTestServer.Web.Endpoint.url <> "/#{org}/#{system}/#{fw}"
  end

  def fetch_build(vcs_id) do
    q = from b in Build,
      where: b.vcs_id == ^vcs_id,
      select: b
    Repo.one(q)
  end

  def create_build(org, system, vcs_id, device) do
    build =
      %Build{
        org: org,
        system: system,
        vcs_id: vcs_id,
        device: device
      }
    Repo.insert!(build)
  end

end
