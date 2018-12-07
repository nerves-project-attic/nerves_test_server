defmodule NervesTestServer.Test.Context do
  defstruct [
    uuid: nil,
    platform: nil,
    architecture: nil,
    tags: [],
    tag: nil,
    repo_sha: nil,
    repo_org: nil,
    repo_name: nil,
    repo_pr: nil
  ]

  def parse(context) when is_binary(context) do
    context
    |> Jason.decode!()
    |> parse()
  end
  def parse(context) when is_map(context) do
    %__MODULE__{
      uuid: get!(context, "meta-uuid"),
      platform: get!(context, "meta-platform"),
      architecture: get!(context, "meta-architecture"),
      tags: context["tags"] || [],
      tag: get!(context, "meta-platform"),
      repo_sha: context["repo_sha"],
      repo_org: context["repo_org"],
      repo_name: context["repo_name"],
      repo_pr: context["repo_pr"]
    }
  end

  defp get!(values, key) do
    values[key] || raise "#{key} missing"
  end
end
