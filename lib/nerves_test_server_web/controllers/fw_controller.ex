defmodule NervesTestServerWeb.FwController do
  use NervesTestServerWeb, :controller

  def firmware(conn, params) do
    org = Map.get(params, "org")
    repo = Map.get(params, "repo")
    fw = Map.get(params, "fw")
    path = "test_server" <> "/#{org}/#{repo}/#{fw}"

    response =
      ExAws.S3.get_object("nerves", path)
      |> ExAws.request
    case response do
      {:ok, %{body: firmware} = resp} ->
        conn
        |> put_resp_header("content-disposition",
                           "attachment; filename=#{fw}")
        |> send_resp(200, firmware)
      {_, error} ->
        conn
        |> send_resp(500, error)
    end

  end
end
