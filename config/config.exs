# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :nerves_test_server,
  ecto_repos: [NervesTestServer.Repo]

# Configures the endpoint
config :nerves_test_server, NervesTestServerWeb.Endpoint,
  url: [host: "169.254.37.89"],
  secret_key_base: "38LtmKGJZBrYawg1qVj6dhQt6yCu2IsMOCy1pFp3XQiGFUBOXSOAUB5lqKeFmzAv",
  render_errors: [view: NervesTestServerWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: NervesTestServer.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure AWS access
config :ex_aws,
  access_key_id: [{:system, "NERVES_AWS_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "NERVES_AWS_SECRET_ACCESS_KEY"}, :instance_role]

config :circle_ci,
  token: System.get_env("NERVES_CIRCLECI_TOKEN"),
  json_module: Poison

config :tentacat, 
  token: System.get_env("NERVES_GITHUB_TOKEN")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
