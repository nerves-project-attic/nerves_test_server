defmodule NervesTestServer.Test do
  @moduledoc """

  """

  defstruct [
    pid: nil,
    tag: nil,
    timeout_ref: nil,
    status: :pending,
    device: nil,
    context: nil
  ]

  use GenServer

  @timeout 1000 * 60 * 20 # 20 minutes

  def start_link(tag, context) do
    GenServer.start_link(__MODULE__, {tag, context})
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  def init({tag, context}) do
    {:ok, %__MODULE__{
      pid: self(),
      tag: tag,
      context: context,
      timeout_ref: :timer.exit_after(@timeout, :normal)
    }, {:continue, nil}}
  end

  def handle_continue(nil, context) do
    {:noreply, context}
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
