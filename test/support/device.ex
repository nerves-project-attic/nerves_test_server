defmodule NervesTestServer.TestDevice do
  use GenServer

  def start_link(params) do
    GenServer.start_link(params)
  end

  def init(params) do
    {:ok, params}
  end
end
