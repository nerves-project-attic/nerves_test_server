defmodule NervesTestServer.Device do
  defstruct [
    pid: nil,
    serial: nil,
    tags: [],
    sha: nil,
    test_results: nil,
    test_io: nil,
    status: :ready
  ]
end
