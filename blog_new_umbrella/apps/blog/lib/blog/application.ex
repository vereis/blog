defmodule Blog.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      Blog.Repo.Postgres,
      Blog.Repo.SQLite,
      {DNSCluster, query: Application.get_env(:blog, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Blog.PubSub}
      # Start a worker by calling: Blog.Worker.start_link(arg)
      # {Blog.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Blog.Supervisor)
  end
end
