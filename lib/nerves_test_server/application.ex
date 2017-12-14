defmodule NervesTestServer.Application do
  use Application

  @producer Application.get_env(:nerves_test_server, :producer)
  @producer_opts Application.get_env(:nerves_test_server, @producer)

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec



    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(NervesTestServer.Repo, []),
      supervisor(NervesTestServerWeb.Endpoint, []),
      worker(@producer, [@producer_opts]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NervesTestServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
