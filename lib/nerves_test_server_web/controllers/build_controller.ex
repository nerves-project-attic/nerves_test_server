defmodule NervesTestServerWeb.BuildController do
  use NervesTestServerWeb, :controller

  import Ecto.Query

  def org_index(conn, %{"org" => org}) do
    builds =
      Repo.all(
        from b in Build,
        where: b.org == ^org,
        order_by: [desc: :inserted_at],
        limit: 50)
      |> set_build_status()
    render conn, "index.html", org: org, builds: builds
  end

  def repo_index(conn, %{"org" => org, "repo" => repo}) do
    builds =
      Repo.all(
        from b in Build,
        where: b.org == ^org,
        where: b.system == ^repo,
        order_by: [desc: :inserted_at],
        limit: 50)
      |> set_build_status()
    render conn, "index.html", org: org, repo: repo, builds: builds
  end

  def show(conn, %{"build" => build_id}) do
    build =
      Repo.get(Build, build_id)
      |> set_build_status()
    render conn, "show.html", build: build
  end

  defp set_build_status(builds) when is_list(builds) do
    Enum.map(builds, fn build ->
      set_build_status(build)
    end)
  end
  defp set_build_status(build) do
    case build.result do
      nil ->
        build
        |> Map.from_struct()
        |> Map.put(:status, "Running")
      %{"failures" => 0} ->
        build
        |> Map.from_struct()
        |> Map.put(:status, "Pass")
      _ ->
        build
        |> Map.from_struct()
        |> Map.put(:status, "Fail")
    end
  end

end
