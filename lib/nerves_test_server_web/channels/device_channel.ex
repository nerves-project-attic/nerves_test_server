defmodule NervesTestServerWeb.DeviceChannel do
  use NervesTestServerWeb, :channel
  require Logger
  alias NervesTestServer.Device

  @producer Application.get_env(:nerves_test_server, :producer)

  def join("device:" <> device, payload, socket) do
    system = Map.get(payload, "system")
    status = Map.get(payload, "status")
    Logger.debug """
      Joined
      Device: #{device}
      System: #{system}
    """
    #Logger.debug "Params: #{inspect payload}"
    if status == "ready" do
      connect(device, "device:" <> device, system)
    end

    socket =
      socket
      |> assign(:device, device)
      |> assign(:system, system)
    {:ok, socket}
  end

  def handle_in("test_begin", _payload, socket) do
    #TODO: Unlink from the device genserver and set the timers
    device = socket.assigns[:device]
    Device.test_begin(pname(device))
    {:reply, {:ok, %{"test" => "begin"}}, socket}
  end

  def handle_in("test_results", payload, socket) do
    device = socket.assigns[:device]
    system = socket.assigns[:system]
    result_payload = Map.take(payload, ["test_results", "test_io"])
    result = Map.get(result_payload, "test_results")
    Logger.debug "Payload: #{inspect payload}"
    Logger.debug """
      Test Results
      Device: #{device}
      System: #{system}
      Result: #{inspect result}
    """
    if pid = Process.whereis(pname(device)) do
      Device.test_result(pid, result_payload)
    else
      connect(device, "device:" <> device, system)
    end

    {:reply, {:ok, %{test: :ok}}, socket}
  end

  def connect(device, topic, system) do
    pidname = pname(device)
    if pid = Process.whereis(pidname) do
      {:ok, pid}
    else
      NervesTestServer.Device.start_link(
        device, 
        system, 
        topic,
        @producer, 
        [name: pidname])
    end
  end

  def remove(device) do
    pidname = pname(device)
    if Process.whereis(pidname) do
      Process.exit(pidname, :normal)
    else
      {:error, :not_started}
    end
  end

  defp pname(device) do
    String.to_atom("NervesTestServer.Device." <> device)
  end

end
