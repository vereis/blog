# BlogWeb

Phoenix web interface for [vereis.com](https://vereis.com) - a personal blog and portfolio site.

## Features

- **LiveView Pages** - Real-time updates for posts, projects, and gallery
- **Full-Text Search** - SQLite FTS5 powered search across posts
- **RSS Feed** - Auto-generated RSS feed at `/rss`
- **Discord Status** - Live Discord presence display via Lanyard
- **Viewer Count** - Real-time page viewer tracking via Phoenix Presence
- **Optimized Images** - WebP with CSS-only LQIP progressive loading

## Architecture

This is the web layer of an [umbrella project](../../README.md). It handles HTTP requests, LiveView interactions, and asset serving.

### Routes

| Path | Handler | Description |
|------|---------|-------------|
| `/` | `HomeLive` | Landing page |
| `/posts` | `PostsLive` | Blog post listing with search/filter |
| `/posts/:slug` | `PostsLive` | Individual post view |
| `/projects` | `ProjectsLive` | Portfolio projects |
| `/gallery` | `GalleryLive` | Image gallery |
| `/rss` | `RssController` | RSS feed |
| `/assets/images/:name` | `AssetsController` | Optimized image serving |
| `/:permalink` | `PermalinkController` | Legacy URL redirects |

### Components

Located in `lib/blog_web/components/`:

| Component | Description |
|-----------|-------------|
| `header.ex` | Site navigation header |
| `footer.ex` | Site footer |
| `post.ex` | Blog post card and full view |
| `project.ex` | Project card display |
| `search.ex` | Search input with debouncing |
| `tag.ex` | Tag badges |
| `aside/` | Sidebar components (TOC, Discord, viewers) |

### Real-time Features

**Phoenix Presence** tracks active viewers per page:

```elixir
defmodule BlogWeb.Presence do
  use Phoenix.Presence,
    otp_app: :blog_web,
    pubsub_server: Blog.PubSub
end
```

**Discord Presence** displays current status via WebSocket connection to Lanyard.

## Development

```bash
cd apps/blog_web
mix setup
mix phx.server
```

Visit [localhost:4000](http://localhost:4000).

### Asset Pipeline

- **CSS**: Tailwind CSS v4 with custom components in `assets/css/`
- **JS**: esbuild bundling from `assets/js/app.js`
- **Fonts**: Self-hosted in `priv/static/fonts/`

## Testing

```bash
cd apps/blog_web
mix test
```

Tests use `Phoenix.LiveViewTest` and `LazyHTML` for component testing.

## Deployment

Deployed to [Fly.io](https://fly.io) with:
- LiteFS for distributed SQLite
- Auto-scaling machines
- Health checks at `/health`

See [fly.toml](../../fly.toml) for configuration.