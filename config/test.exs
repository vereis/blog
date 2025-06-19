import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :blog, Blog.Repo.Postgres,
  username: System.fetch_env!("POSTGRES_USER"),
  password: System.fetch_env!("POSTGRES_PASSWORD"),
  hostname: "localhost",
  port: String.to_integer(System.fetch_env!("POSTGRES_PORT")),
  database: "#{System.fetch_env!("POSTGRES_DB")}_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# Configure SQLite database for testing
config :blog, Blog.Repo.SQLite,
  database: "#{System.fetch_env!("DATABASE_PATH")}_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :blog_web, BlogWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "WQ6Qx69Cigy0gmaPFyzlQxCOeIiIQFpR5XsdJert0ESc4FKfiQ37i1tw+8gMLLbQ",
  server: false

config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Configure Lanyard with test values
config :blog,
  lanyard_discord_user_id: "382588737441497088",
  lanyard_poll_interval: 120_000
