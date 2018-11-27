defmodule NervesTestServer.Test do
  @moduledoc """

  """
  use GenServer

  alias NervesTestServer.Test.Context

  def start_link(%Context{} = ctx) do
    GenServer.start_link(__MODULE__, ctx)
  end

  def init(ctx) do
    {:ok, ctx, {:continue, nil}}
  end

  def handle_continue(nil, state) do
    {:noreply, state}
  end

  # defp set_github_status(state, context) do
  #   status = %{
  #     "state" => state,
  #     "target_url" => "", # this should be set to a URL on this server
  #     "description" => description,
  #     "context" => context
  #   }
  #   NervesHubServer.Tentacat.client()
  #   |> Tentacat.Repositories.Statuses.create(status)
  # end

end
