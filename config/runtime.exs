import Config

# Configure Lanyard integration
config :blog,
  lanyard_discord_user_id: System.fetch_env!("LANYARD_DISCORD_USER_ID"),
  lanyard_poll_interval: String.to_integer(System.fetch_env!("LANYARD_POLL_INTERVAL")) * 1000

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.
if config_env() == :prod do
  import Config

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  # maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :blog, Blog.Repo.Postgres,
    ssl: false,
    socket_options: [:inet6],
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  # Configure SQLite database for production
  config :blog, Blog.Repo.SQLite,
    database: System.fetch_env!("DATABASE_PATH"),
    pool_size: String.to_integer(System.fetch_env!("SQLITE_POOL_SIZE"))

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :blog_web, BlogWeb.Endpoint,
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("BLOG_PORT") || "4000")
    ],
    url: [host: System.fetch_env!("BLOG_HOST"), port: System.fetch_env!("BLOG_PORT")],
    secret_key_base: secret_key_base

  # ## Using releases
  #
  # If you are doing OTP releases, you need to instruct Phoenix
  # to start each relevant endpoint:
  #
  #     config :blog_web, BlogWeb.Endpoint, server: true
  #
  # Then you can assemble a release by calling `mix release`.
  # See `mix help release` for more information.

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :blog_web, BlogWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :blog_web, BlogWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  config :blog, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")
end
