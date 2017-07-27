defmodule NervesTestServer.Web.PageController do
  use NervesTestServer.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

end
