defmodule NervesTestServer.Web.Router do
  use NervesTestServer.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", NervesTestServer.Web do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index

    get "/:org", BuildController, :org_index
    get "/:org/:repo", BuildController, :repo_index
    get "/:org/:repo/:build", BuildController, :show

    get "/:org/:repo/:build/:fw", FwController, :firmware
  end

  # Other scopes may use custom stacks.
  # scope "/api", NervesTestServer.Web do
  #   pipe_through :api
  # end
end
