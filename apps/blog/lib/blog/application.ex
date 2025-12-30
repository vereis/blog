defmodule Blog.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      Enum.reject(
        [
          Blog.Repo,
          {Ecto.Migrator, repos: Application.fetch_env!(:blog, :ecto_repos), skip: System.get_env("RELEASE_NAME") == nil},
          {DNSCluster, query: Application.get_env(:blog, :dns_cluster_query) || :ignore},
          {Phoenix.PubSub, name: Blog.PubSub},
          Blog.env() != :test && Blog.Discord.Presence,
          Blog.env() == :prod &&
            {EctoLiteFS.Supervisor,
             repo: Blog.Repo,
             primary_file: "/litefs/.primary",
             poll_interval: 30_000,
             erpc_timeout: to_timeout(second: 30),
             event_stream_url: "http://localhost:20202/events"},
          Blog.env() != :test &&
            {Blog.Resource.Watcher, schemas: [Blog.Assets.Asset, Blog.Posts.Post, Blog.Projects.Project]}
        ],
        &(!&1)
      )

    Supervisor.start_link(children, strategy: :one_for_one, name: Blog.Supervisor)
  end
end
