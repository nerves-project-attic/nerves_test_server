defmodule NervesTestServer.SchedulerTest do
  use ExUnit.Case

  alias NervesTestServer.{Scheduler, Device}

  test "schedule tests" do
    ctx =
      Path.expand("test/fixtures/context.json")
      |> File.read!()
      |> Jason.decode!
    tags = ctx["tags"]
    {:ok, tag_tests} = Scheduler.schedule_tests(ctx)
    Enum.each(tags, fn(tag) ->
      Enum.each(tag_tests[tag], fn(test) ->
        assert test in Scheduler.scheduled_tests(tag)
      end)
    end)

    Enum.each(tags, fn(tag) ->
      Enum.each(tag_tests[tag], fn(test) ->
        assert test not in Scheduler.cancel_test(tag, test)
      end)
    end)
  end

  test "devices are assigned to tests" do

  end

end
