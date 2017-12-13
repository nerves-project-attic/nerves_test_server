defmodule NervesTestServerWeb.PageController do
  use NervesTestServerWeb, :controller

  def index(conn, _params) do
    redirect(conn, to: "/nerves-project/")
  end

end
