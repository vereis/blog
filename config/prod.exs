import Config

config :blog_web, BlogWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

# Fly.io terminates SSL at the proxy level
# config :blog_web, BlogWeb.Endpoint,
#   force_ssl: [rewrite_on: [:x_forwarded_proto]]

config :logger, level: :info
