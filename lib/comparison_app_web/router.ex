defmodule ComparisonAppWeb.Router do
  use ComparisonAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ComparisonAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug ComparisonAppWeb.Plugs.SessionId
    plug ComparisonAppWeb.Plugs.ClientIp
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ComparisonAppWeb do
    pipe_through :browser

    live_session :default, on_mount: {ComparisonAppWeb.LiveMount, :assign_session_id} do
      live "/", CompareLive, :index
      live "/ratings", RatingsLive, :index
      live "/streamers/:id", StreamerLive, :show
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", ComparisonAppWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:comparison_app, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ComparisonAppWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
