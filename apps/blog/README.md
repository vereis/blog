# Blog

Core domain logic for [vereis.com](https://vereis.com) - a personal blog and portfolio site.

## Features

- **Posts** - Markdown-based blog posts with YAML frontmatter, syntax highlighting, and full-text search
- **Projects** - Portfolio showcase loaded from YAML configuration
- **Assets** - Image processing pipeline with LQIP and WebP conversion
- **Tags** - Tagging system for posts and projects
- **Discord Presence** - Real-time Discord status via [Lanyard](https://github.com/Phineas/lanyard)

## Architecture

This is the core business logic layer of an [umbrella project](../../README.md). It handles all data access, content processing, and domain operations.

### Contexts

| Context | Description |
|---------|-------------|
| `Blog.Posts` | CRUD operations for blog posts |
| `Blog.Projects` | CRUD operations for portfolio projects |
| `Blog.Assets` | Image asset management and processing |
| `Blog.Tags` | Tag management with auto-creation on reference |
| `Blog.Discord` | Discord presence facade over ETS cache |

### Resource System

The `Blog.Resource` behaviour provides a unified pattern for importing content from the filesystem:

```elixir
defmodule Blog.Posts.Post do
  use Blog.Resource,
    source_dir: "priv/posts",
    preprocess: &Blog.Tags.label_to_id/1,
    import: &Blog.Posts.upsert_post/1

  @impl Blog.Resource
  def handle_import(%Blog.Resource{content: content}) do
    # Parse YAML frontmatter and markdown body
    # Return attrs map for upserting
  end
end
```

Resources are automatically imported on application boot via `Blog.Resource.Watcher`, which also watches for filesystem changes in development.

### Distributed SQLite with LiteFS

The blog uses SQLite with [LiteFS](https://fly.io/docs/litefs/) for distributed replication across Fly.io machines. Write operations are automatically forwarded to the primary node via [EctoLiteFS](https://hex.pm/packages/ecto_litefs).

```elixir
defmodule Blog.Repo do
  use Ecto.Repo, otp_app: :blog, adapter: Ecto.Adapters.SQLite3
  use EctoMiddleware.Repo

  @impl EctoMiddleware.Repo
  def middleware(_action, _resource) do
    [EctoLiteFS.Middleware]
  end
end
```

See the [EctoLiteFS documentation](https://hexdocs.pm/ecto_litefs/) and [GitHub repository](https://github.com/vereis/ecto_litefs) for more details on the write forwarding middleware.

## Content Format

### Posts

Posts are markdown files in `priv/posts/` with YAML frontmatter:

```markdown
---
title: "My Post Title"
slug: "my-post-slug"
published_at: 2025-01-01 12:00:00Z
is_draft: false
tags:
  - elixir
  - phoenix
---

Post content in markdown...
```

Generated features:
- Automatic excerpt extraction (first 3 paragraphs)
- Reading time estimation (260 WPM)
- Heading extraction for table of contents
- Full-text search indexing (SQLite FTS5)

### Projects

Projects are defined in `priv/projects/projects.yaml`:

```yaml
- name: my-project
  display_name: My Project
  description: Project description in markdown
  url: https://github.com/user/project
  tags:
    - elixir
```

### Assets

Images placed in `priv/assets/` are automatically:
- Converted to WebP format
- Resized to reasonable dimensions
- Generated with [CSS-only LQIP](https://leanrada.com/notes/css-only-lqip/) hashes for progressive loading

## Mix Tasks

Generate a new post with timestamp:

```bash
mix blog.gen.post "My New Post Title"
# Creates: priv/posts/20250101120000_my_new_post_title.md
```

## Dependencies

Key dependencies used:

| Package | Purpose |
|---------|---------|
| [ecto_litefs](https://hex.pm/packages/ecto_litefs) | Distributed SQLite write forwarding |
| [ecto_middleware](https://hex.pm/packages/ecto_middleware) | Ecto operation middleware pipeline |
| [mdex](https://hex.pm/packages/mdex) | Markdown parsing with syntax highlighting |
| [vix](https://hex.pm/packages/vix) | Image processing (libvips bindings) |
| [floki](https://hex.pm/packages/floki) | HTML parsing and transformation |
| [yaml_elixir](https://hex.pm/packages/yaml_elixir) | YAML parsing for frontmatter |
| [websockex](https://hex.pm/packages/websockex) | Discord presence WebSocket client |

## Testing

```bash
cd apps/blog
mix test
```

Tests use isolated fixtures in `test/fixtures/priv/` to avoid polluting production content.
