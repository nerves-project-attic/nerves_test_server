defmodule NervesTestServer.Device do
  use GenStage
  require Logger

  import Ecto.Query

  alias NervesTestServerWeb.Endpoint
  alias NervesTestServer.{Repo, Build}

  @repo_org "nerves-project"
  # 5 minutes
  @timeout 60_000 * 5

  def start_link(device, system, topic, producer, opts \\ []) do
    GenStage.start_link(__MODULE__, {device, system, topic, producer}, opts)
  end

  def test_begin(pid) do
    GenStage.call(pid, :test_begin)
  end

  def test_result(pid, result) do
    GenStage.call(pid, {:test_result, result})
  end

  def init({device, system, topic, producer}) do
    state = %{
      producer: producer,
      device: device,
      system: system,
      topic: topic,
      message: nil,
      repo_org: @repo_org,
      repo_name: system,
      timeout_t: nil,
      build: nil,
      subscription: nil
    }

    subscriptions = [
      {producer,
       [
         max_demand: 1,
         selector: fn %{repo_org: repo_org, repo_name: repo_name} ->
           String.equivalent?(repo_org, state.repo_org) and
             String.equivalent?(repo_name, state.repo_name)
         end
       ]}
    ]

    {:consumer, state, subscribe_to: subscriptions}
  end

  def handle_subscribe(:producer, _options, subscription, s) do
    GenStage.ask(subscription, 1)
    s = %{s | subscription: subscription}
    {:manual, s}
  end

  def handle_call(:test_begin, {from, _ref}, s) do
    Logger.debug("Device Test Beginning")
    Process.unlink(from)

    build =
      Build.changeset(s.build, %{start_time: DateTime.utc_now()})
      |> Repo.update!()

    {:reply, :ok, [], %{s | build: build}}
  end

  def handle_call({:test_result, _result}, _from, %{build: nil} = s) do
    {:reply, :ok, [], s}
  end

  def handle_call({:test_result, result}, _from, s) do
    if t = s.timeout_t do
      Process.cancel_timer(t)
    end

    result_map = Map.get(result, "test_results")
    result_io = Map.get(result, "test_io")

    change = %{
      end_time: DateTime.utc_now(),
      result: result_map,
      result_io: result_io
    }

    Build.changeset(s.build, change)
    |> Repo.update!()

    Logger.debug("Device Received Results: #{inspect(result)}")
    Logger.debug("Message: #{inspect(s.message)}")

    build_url =
      NervesTestServerWeb.Router.Helpers.build_url(
        NervesTestServerWeb.Endpoint,
        :show,
        s.build.org,
        s.build.system,
        s.build.id
      )

    token = Application.get_env(:tentacat, :token)
    client = Tentacat.Client.new(%{access_token: token})

    Tentacat.Commits.Comments.create(
      s.build.org,
      s.build.system,
      s.build.vcs_id,
      %{
        body: """
        Nerves Hardware Test
        Status: Results Received
        #{inspect(result_map)}
        #{build_url}
        """
      },
      client
    )

    send(self(), :ask)
    s.producer.ack(s.message)
    {:reply, :ok, [], %{s | message: nil, build: nil}}
  end

  def handle_events([], _from, s) do
    Process.sleep(10_000)
    send(self(), :ask)
    {:noreply, [], s}
  end

  def handle_events([message], _from, s) do
    {:noreply, [], process_message(message, s)}
  end

  def handle_info(:timeout, s) do
    Logger.debug("Timeout Expired")

    change = %{
      end_time: DateTime.utc_now(),
      result: %{"timeout" => 0},
      result_io: "Timed out waiting for results"
    }

    Build.changeset(s.build, change)
    |> Repo.update!()

    post_vcs_status(s.build)
    s.producer.ack(s.message)
    send(self(), :ask)

    {:noreply, [], %{s | build: nil, message: nil}}
  end

  def handle_info(:ask, s) do
    GenStage.ask(s.subscription, 1)
    {:noreply, [], s}
  end

  defp process_message(message, s) do
    ## Do something to process message here
    Logger.debug("Received Message: #{inspect(message)}")
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
          Logger.warn("Build: #{vcs_id} already exists")
          GenStage.ask(s.subscription, 1)
          s.producer.ack(s.message)
          %{s | message: nil}
      end

    %{s | message: message}
  end

  def fw_url(org, system, fw) do
    NervesTestServerWeb.Endpoint.url() <> "/#{org}/#{system}/#{fw}"
  end

  def fetch_build(vcs_id) do
    q =
      from(
        b in Build,
        where: b.vcs_id == ^vcs_id,
        select: b
      )

    Repo.one(q)
  end

  def create_build(org, system, vcs_id, device) do
    build = %Build{
      org: org,
      system: system,
      vcs_id: vcs_id,
      device: device
    }

    Repo.insert!(build)
  end

  defp post_vcs_status(%Build{} = build) do
    Application.get_env(:tentacat, :enabled)
    |> post_vcs_github(build)
  end

  defp post_vcs_github(false, _), do: :noop

  defp post_vcs_github(true, %Build{} = build) do
    token = Application.get_env(:tentacat, :token)
    client = Tentacat.Client.new(%{access_token: token})

    build_url =
      NervesTestServerWeb.Router.Helpers.build_url(
        NervesTestServerWeb.Endpoint,
        :show,
        build.org,
        build.system,
        build.id
      )

    Tentacat.Commits.Comments.create(
      build.org,
      build.system,
      build.vcs_id,
      %{
        body: """
        Nerves Hardware Test
        Status: Timed Out

        #{build_url}
        """
      },
      client
    )
  end
end
