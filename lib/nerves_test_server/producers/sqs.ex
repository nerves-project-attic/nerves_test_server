defmodule NervesTestServer.Producers.SQS do
  use NervesTestServer.Producer
  
  alias ExAws.SQS

  def start_link(opts \\ []) do
    GenStage.start_link(__MODULE__, opts, [name: __MODULE__])
  end

  def ack(nil), do: :ok
  def ack(message) do
    GenStage.call(__MODULE__, {:ack, message})
  end

  def init(opts) do
    queue_name = opts[:queue_name] || 
      raise "SQS Producer requires a queue name to be configured"
    state = %{
      demand: 0,
      queue: queue_name
    }

    {:producer, state, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_demand(incoming_demand, %{demand: 0} = state) do
    new_demand = state.demand + incoming_demand

    Process.send(self(), :get_messages, [])

    {:noreply, [], %{state| demand: new_demand}}
  end
  def handle_demand(incoming_demand, state) do
    new_demand = state.demand + incoming_demand

    {:noreply, [], %{state| demand: new_demand}}
  end

  def handle_call({:ack, message}, _from, state) do
    state.queue
    |> SQS.delete_message_batch(make_batch_item(message.meta))
    |> ExAws.request
    {:reply, :ok, [], state}
  end

  def handle_info(:get_messages, state) do
    aws_resp = ExAws.SQS.receive_message(
      state.queue,
      max_number_of_messages: min(state.demand, 10)
    )
    |> ExAws.request

    IO.inspect aws_resp, label: "SQS Response"
    messages = case aws_resp do
      {:ok, resp} ->
        parse(resp.body.messages)
      {:error, _reason} ->
        []
    end

    num_messages_received = Enum.count(messages)
    new_demand = max(state.demand - num_messages_received, 0)
    cond do
      new_demand == 0 -> :ok
      num_messages_received == 0 ->
        Process.send_after(self(), :get_messages, 200)
      true ->
        Process.send(self(), :get_messages, [])
    end

    {:noreply, messages, %{state| demand: new_demand}}
  end

  def parse(messages) do
    Enum.map(messages, fn(message) ->
      body =
        message
        |> Map.get(:body)
        |> Poison.decode!

      meta =
        body
        |> Map.get("Message")
        |> Poison.decode!
        |> IO.inspect(label: "Meta")
      vcs_id = Map.get(meta, "sha")
      repo_org = Map.get(meta, "repo_org")
      repo_name = Map.get(meta, "repo_name")

      build_num = Map.get(meta, "ci_build_num")

      circle_proj =
        %CircleCI.Project{vcs_type: "github"}
        |> Map.put(:username, repo_org)
        |> Map.put(:project, repo_name)

      {:ok, resp} = 
        CircleCI.Project.Build.artifacts(circle_proj, build_num)
      
      fw_url = 
        Enum.find(resp.body, & Map.get(&1, "pretty_path") |> String.ends_with?("fw"))
        |> Map.get("url")
      
      %NervesTestServer.Message{
        meta: Map.take(message, [:message_id, :receipt_handle]),
        repo_org: repo_org,
        repo_name: repo_name, 
        fw_url: fw_url,
        vcs_id: vcs_id
      }
    end)
  end

  defp make_batch_item(message) do
    [%{id: Map.get(message, :message_id), receipt_handle: Map.get(message, :receipt_handle)}]
  end
end
