defmodule NervesTestServer.Tentacat do
  def client do
    access_token = Application.get_env(:tentacat, :access_token)
    Tentacat.Client.new(%{access_token: access_token})
  end

end
