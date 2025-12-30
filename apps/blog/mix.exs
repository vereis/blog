defmodule Blog.MixProject do
  use Mix.Project

  def project do
    [
      app: :blog,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Blog.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:dns_cluster, "~> 0.2.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:ecto_sql, "~> 3.13"},
      {:ecto_sqlite3, ">= 0.0.0"},
      ecto_middleware_dep(),
      {:jason, "~> 1.2"},
      {:ecto_utils, "~> 0.2"},
      {:mdex, "~> 0.2"},
      {:yaml_elixir, "~> 2.11"},
      {:floki, "~> 0.36"},
      {:vix, "~> 0.31"},
      {:mime, "~> 2.0"},
      {:file_system, "~> 1.0"},
      {:websockex, "~> 0.5"},
      {:ex_machina, "~> 2.8", only: :test},
      {:html5ever, "~> 0.17.0"},
      ecto_litefs_dep()
    ]
  end

  # Use local path for development, git branch for CI
  # See ECTO_MIDDLEWARE_V2_DESIGN.md for details
  defp ecto_middleware_dep do
    if local_dep_path_exists?("ecto_middleware") do
      {:ecto_middleware, path: "../../../ecto_middleware", override: true}
    else
      {:ecto_middleware, "~> 2.0"}
    end
  end

  defp ecto_litefs_dep do
    cond do
      # Docker build: ecto_litefs copied to /app/ecto_litefs
      File.exists?("/app/ecto_litefs/mix.exs") ->
        {:ecto_litefs, path: "/app/ecto_litefs", override: true}

      # Local dev: ecto_litefs sibling directory
      local_dep_path_exists?("ecto_litefs") ->
        {:ecto_litefs, path: "../../../ecto_litefs", override: true}

      # Fallback to GitHub (CI without Docker)
      true ->
        {:ecto_litefs, github: "vereis/ecto_litefs", branch: "master"}
    end
  end

  defp local_dep_path_exists?(name) do
    not ci?() and File.exists?(Path.expand("../../../#{name}/mix.exs", __DIR__))
  end

  defp ci?, do: System.get_env("CI") == "true"

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run #{__DIR__}/priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
