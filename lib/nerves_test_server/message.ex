defmodule NervesTestServer.Message do
  defstruct [
    meta: %{},
    repo_name: nil,
    repo_org: nil,
    fw_url: nil,
    vcs_id: nil
  ]

  @type t :: %__MODULE__{
    meta: map,
    repo_name: String.t,
    repo_org: String.t,
    fw_url: String.t,
    vcs_id: String.t
  }
end
