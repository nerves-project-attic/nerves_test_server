defmodule NervesTestServer.Web.PageController do
  use NervesTestServer.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def firmware(conn, _params) do
    firmware =
      "/Users/jschneck/Developer/nerves/nerves_system_test/_build/rpi0/dev/nerves/images/nerves_system_test.fw"
    conn
    |> put_resp_header("content-disposition",
                       ~s(attachment; filename=nerves_system_test.fw))
    |> send_file(200, firmware)
  end
end
