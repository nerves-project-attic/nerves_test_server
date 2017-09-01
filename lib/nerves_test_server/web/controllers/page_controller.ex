defmodule NervesTestServer.Web.PageController do
  use NervesTestServer.Web, :controller

  def index(conn, _params) do
    redirect(conn, to: "/nerves-project/")
  end

end
