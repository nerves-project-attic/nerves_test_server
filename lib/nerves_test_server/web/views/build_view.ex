defmodule NervesTestServer.Web.BuildView do
  use NervesTestServer.Web, :view

  def table_class_for_build_status(status) do
    case status do
      "Pass" -> "table-success"
      "Fail" -> "table-danger"
      _ -> ""
    end
  end
end
