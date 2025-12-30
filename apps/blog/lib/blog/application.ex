defmodule Blog.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      Enum.reject(
        [
          Blog.Repo,
          {Ecto.Migrator, repos: Application.fetch_env!(:blog, :ecto_repos), skip: skip_migrations?()},
          {DNSCluster, query: Application.get_env(:blog, :dns_cluster_query) || :ignore},
          {Phoenix.PubSub, name: Blog.PubSub},
          Blog.env() != :test && Blog.Discord.Presence,
          Blog.env() == :prod && ecto_litefs_supervisor()
          # TODO: Re-enable after implementing Ecto middleware for write forwarding
          # Blog.env() != :test &&
          #   {Blog.Resource.Watcher, schemas: [Blog.Assets.Asset, Blog.Posts.Post, Blog.Projects.Project]}
        ],
        &(!&1)
      )

    Supervisor.start_link(children, strategy: :one_for_one, name: Blog.Supervisor)
  end

  defp ecto_litefs_supervisor do
    {EctoLiteFS.Supervisor,
     repo: Blog.Repo,
     primary_file: "/litefs/.primary",
     poll_interval: 30_000,
     erpc_timeout: to_timeout(second: 30),
     event_stream_url: "http://localhost:20202/events"}
  end

  defp skip_migrations? do
    # Skip migrations in development/test, run automatically in releases
    # SQLite/LiteFS handles concurrent migration attempts via locks
    System.get_env("RELEASE_NAME") == nil
  end
end
