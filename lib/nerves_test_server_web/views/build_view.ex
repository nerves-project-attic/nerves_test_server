defmodule NervesTestServerWeb.BuildView do
  use NervesTestServerWeb, :view

  def table_class_for_build_status(status) do
    case status do
      "Pass" -> "table-success"
      "Fail" -> "table-danger"
      "Timeout" -> "table-danger"
      _ -> ""
    end
  end
end
