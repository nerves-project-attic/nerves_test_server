defmodule NervesTestServer.Application do
  use Application

  @queue "nerves-test-server"

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(NervesTestServer.Repo, []),
      # Start the endpoint when the application starts
      supervisor(NervesTestServer.Web.Endpoint, []),
      # Start your own worker by calling: NervesTestServer.Worker.start_link(arg1, arg2, arg3)
      # worker(NervesTestServer.Worker, [arg1, arg2, arg3]),
      worker(NervesTestServer.SQSProducer, [@queue, [name: :sqs_producer]]),
      #worker(NervesTestServer.SQSDecoder, [[name: :sqs_decoder]]),
      #worker(NervesTestServer.Device, ["rpi0", @queue, [:sqs_producer]])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NervesTestServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
