defmodule NervesTestServer.Web.DeviceChannel do
  use NervesTestServer.Web, :channel
  require Logger
  alias NervesTestServer.Device

  def join("device:" <> device, %{"target" => target}, socket) do
    Logger.debug "Device #{device} Joined"
    #Logger.debug "Params: #{inspect payload}"
    connect(device, "device:" <> device, target)
    socket =
      assign(socket, :device, device)
    {:ok, socket}
  end

  def handle_in("test_results", payload, socket) do
    Logger.debug "#{socket.assigns[:device]} Received Results: #{inspect payload}"
    result(socket.assigns[:device], payload) |> IO.inspect
    {:reply, {:ok, %{status: "results_received"}}, socket}
  end

  def connect(device, topic, target) do
    pidname = pname(device)
    if pid = Process.whereis(pidname) do
      {:ok, pid}
    else
      NervesTestServer.Device.start_link(device, topic, target, [name: pidname])
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
