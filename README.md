# vereis.com

[![CI Status](https://github.com/vereis/blog_2/workflows/CI/badge.svg)](https://github.com/vereis/blog_2/actions)

Personal blog and portfolio site built with Phoenix LiveView, SQLite, and LiteFS.

**Live at [vereis.com](https://vereis.com)**

## Architecture

Phoenix umbrella application with two apps:

| App | Description |
|-----|-------------|
| [blog](apps/blog/README.md) | Core domain logic - posts, projects, assets, tags |
| [blog_web](apps/blog_web/README.md) | Phoenix web interface - LiveView pages, components |

### Tech Stack

- **Framework**: [Phoenix](https://phoenixframework.org/) 1.8 with [LiveView](https://hexdocs.pm/phoenix_live_view)
- **Database**: SQLite with [Ecto](https://hexdocs.pm/ecto)
- **Distributed**: [LiteFS](https://fly.io/docs/litefs/) replication via [EctoLiteFS](https://hex.pm/packages/ecto_litefs)
- **Markdown**: [MDEx](https://hex.pm/packages/mdex) with syntax highlighting
- **Images**: [Vix](https://hex.pm/packages/vix) (libvips) + [CSS-only LQIP](https://leanrada.com/notes/css-only-lqip/)
- **Hosting**: [Fly.io](https://fly.io)

## Quick Start

### Nix Users

The project includes a Nix flake for reproducible development environments:

```bash
# Enter dev shell (or use direnv)
nix develop

# Install dependencies and setup
mix setup

# Start Phoenix server
mix phx.server
```

The flake provides Elixir, Erlang, Rust (for native dependencies), and platform-specific tools automatically.

### Manual Setup

Requires:
- Elixir 1.17+
- Erlang/OTP 27+
- Rust (nightly, for MDEx)
- libvips (for image processing)

```bash
mix setup
mix phx.server
```

Visit [localhost:4000](http://localhost:4000).

## Development

### Commands

```bash
# Run tests
mix test

# Pre-commit checks (format, lint, dialyzer, test)
make precommit

# Generate new blog post
mix blog.gen.post "My Post Title"
```

### Content

- **Posts**: Markdown files in `apps/blog/priv/posts/`
- **Projects**: YAML config in `apps/blog/priv/projects/projects.yaml`
- **Assets**: Images in `apps/blog/priv/assets/`

See [apps/blog/README.md](apps/blog/README.md) for content format details.

## Deployment

Deployed to Fly.io with distributed SQLite via LiteFS:

```bash
make deploy       # Deploy to Fly.io
make logs         # Tail logs (all regions)
make ssh          # SSH into instance
make remote       # Open IEx remote shell
```

Configuration in [fly.toml](fly.toml) and [litefs.yml](litefs.yml).

## Related Projects

This blog uses several open-source libraries I maintain:

| Project | Description |
|---------|-------------|
| [EctoLiteFS](https://github.com/vereis/ecto_litefs) | LiteFS-aware Ecto middleware for automatic write forwarding |
| [EctoMiddleware](https://github.com/vereis/ecto_middleware) | Middleware pipeline pattern for Ecto operations |
| [EctoHooks](https://github.com/vereis/ecto_hooks) | Before/after callbacks for Ecto schemas |

## License

MIT