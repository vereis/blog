import Config

config :blog_web, BlogWeb.Endpoint, http: [port: String.to_integer(System.get_env("PORT", "4000"))]

if System.get_env("PHX_SERVER") do
  config :blog_web, BlogWeb.Endpoint, server: true
end

config :blog, :env, config_env()

config :blog,
  discord_user_id: System.get_env("DISCORD_USER_ID", "382588737441497088")

if config_env() == :prod do
  database_path =
    System.get_env("DATABASE_PATH") ||
      raise """
      environment variable DATABASE_PATH is missing.
      For example: /etc/blog/blog.db
      """

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :blog, Blog.Repo,
    database: database_path,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5"),
    default_transaction_mode: :immediate

  config :blog, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :blog_web, BlogWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}],
    check_origin: ["https://#{host}", "https://www.#{host}"],
    secret_key_base: secret_key_base
end
