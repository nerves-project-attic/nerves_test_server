defmodule NervesTestServer.Producer do
  
  @callback start_link(opts :: [any]) :: GenStage.on_start
  @callback ack(message :: NervesTestServer.Message.t) :: :ok | {:error, reason :: any}

  defmacro __using__(_opts) do
    quote do
      @behaviour NervesTestServer.Producer
      use GenStage
      require Logger
    end
  end
end
