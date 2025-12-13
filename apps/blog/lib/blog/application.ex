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
          Blog.env() != :test &&
            {Blog.Resource.Watcher, schemas: [Blog.Assets.Asset, Blog.Posts.Post, Blog.Projects.Project]}
        ],
        &(!&1)
      )

    Supervisor.start_link(children, strategy: :one_for_one, name: Blog.Supervisor)
  end

  defp skip_migrations? do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") == nil
  end
end
