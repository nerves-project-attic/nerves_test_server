defmodule NervesTestServerWeb.Router do
  use NervesTestServerWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", NervesTestServerWeb do
    # Use the default browser stack
    pipe_through(:browser)

    get("/", PageController, :index)

    get("/:org", BuildController, :org_index)
    get("/:org/:repo", BuildController, :repo_index)
    get("/:org/:repo/:build", BuildController, :show)
  end

  # Other scopes may use custom stacks.
  # scope "/api", NervesTestServerWeb do
  #   pipe_through :api
  # end
end
