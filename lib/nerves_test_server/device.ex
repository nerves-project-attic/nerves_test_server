defmodule NervesTestServer.Device do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  def tags(pid) do
    GenServer.call(pid, :tags)
  end

  def init(opts) do
    tags = opts[:tags] || []

    {:ok, %{
      tags: tags
    }}
  end

  def handle_call(:tags, _from, s) do
    {:reply, s.tags, s}
  end
end
