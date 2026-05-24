defmodule ComparisonApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ComparisonAppWeb.Telemetry,
      ComparisonApp.Repo,
      {Oban, Application.fetch_env!(:comparison_app, Oban)},
      {DNSCluster, query: Application.get_env(:comparison_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ComparisonApp.PubSub},
      # Start a worker by calling: ComparisonApp.Worker.start_link(arg)
      # {ComparisonApp.Worker, arg},
      # Start to serve requests, typically the last entry
      ComparisonAppWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ComparisonApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ComparisonAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
