defmodule NervesTestServerWeb.PageController do
  use NervesTestServerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
