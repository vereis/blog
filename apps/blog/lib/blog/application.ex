defmodule Blog.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    base_children = [
      Blog.Repo.Postgres,
      Blog.Repo.SQLite,
      Blog.Release.Migrator,
      {DNSCluster, query: Application.get_env(:blog, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Blog.PubSub},
      Blog.Resource.Watcher
    ]

    children =
      case Blog.env() do
        :test -> base_children
        _env -> base_children ++ [Blog.Lanyard.Supervisor]
      end

    Supervisor.start_link(children, strategy: :one_for_one, name: Blog.Supervisor)
  end
end
