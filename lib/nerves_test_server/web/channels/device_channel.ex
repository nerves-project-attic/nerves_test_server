defmodule NervesTestServer.Web.DeviceChannel do
  use NervesTestServer.Web, :channel
  require Logger
  alias NervesTestServer.Device

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

  def handle_in("test_begin", payload, socket) do
    #TODO: Unlink from the device genserver and set the timers
    {:reply, {:ok, %{"test" => "begin"}}, socket}
  end

  def handle_in("test_results", payload, socket) do
    device = socket.assigns[:device]
    system = socket.assigns[:system]
    result_payload = Map.take(payload, ["test_result", "test_io"])
    result = Map.get(result_payload, "test_result")
    Logger.debug """
      Test Results
      Device: #{device}
      System: #{system}
      Result: #{result}
    """
    connect(device, "device:" <> device, system)
    result(device, result_payload)
    {:reply, {:ok, %{test: :ok}}, socket}
  end

  def connect(device, topic, system) do
    pidname = pname(device)
    if pid = Process.whereis(pidname) do
      {:ok, pid}
    else
      NervesTestServer.Device.start_link(device, system, topic, [name: pidname])
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

  def result(device, result) do
    pidname = pname(device)
    if pid = Process.whereis(pidname) do
      Device.result(pid, result)
    else
      {:error, :not_started}
    end
  end

  defp pname(device) do
    String.to_atom("NervesTestServer.Device." <> device)
  end

end
