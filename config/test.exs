import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :blog, Blog.Repo,
  database: Path.expand("../blog_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox,
  default_transaction_mode: :immediate

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :blog_web, BlogWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "BgbdoRqLI8UKgPtbjA1cdBUUxB2U1814lqsZ1X5wvxIErdzKtgMlEkWBMgTNnqGN",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
